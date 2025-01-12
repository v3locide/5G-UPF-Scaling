#!/bin/bash

# Constants
NAMESPACE=${1:-default}  # Default namespace is 'default'
URANSIM1_INT_ADDR="12.1.1.2"
URANSIM_INT_NAME="uesimtun0"
UPF1_ADDR="12.1.1.4"
UPF2_ADDR="12.1.2.11"

# Command to run iperf on UPF (server)
COMMAND="iperf -s -i 1 -B "$UPF1_ADDR""

# Boolean var to signal iperf traffic (when there is traffic)
TRAFFIC=0

# Function to retrieve pod names
get_pod_name(){
  pod_name=$(kubectl get pods -l $1 -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
  echo  $pod_name
}

# Funcrion to start iperf session between UPFs and URANSIMs with half the throughput
start_traffic(){

        # Checks if URANSIM2 got its interface (after its deployment)
        GOT_INTERFACE=0
        while [ $GOT_INTERFACE -eq 0 ]; do
          URANSIM2_INT=$(kubectl exec -i "$URANSIM2" -- bash -c "ip a" | grep "$URANSIM_INT_NAME")
          if [[ -n "$URANSIM2_INT" ]]; then
            GOT_INTERFACE=1
            echo "Got '$URANSIM_INT_NAME' interface."
          else
            echo "Getting '$URANSIM_INT_NAME' interface..."
            sleep 2
          fi
        done
        URANSIM2_INT_ADDR=$(kubectl exec -i $1 -- bash -c "ip a" | \
        grep -A1 "uesimtun0" | \
        grep "inet " | \
        awk '{print $2}' | \
        cut -d'/' -f1)
        echo "UE2 address: $URANSIM2_INT_ADDR"

        # Starts iperf on UPF2 (server)
        echo "Starting iperf server on UPF2..."
        kubectl exec -i "$2" -- bash -c "iperf -s -i 1 -B "$UPF2_ADDR"" &
        sleep 3

        # Starts iperf with half the original traffic on URANSIM2 (client) and stores the traffic output in "logs/UE2_traffic.log"
        echo "Started iperf client on URANSIM2 (check the logs)."
        kubectl exec -i "$1" -- bash -c "iperf -i 1 -B "$URANSIM2_INT_ADDR" -c "$UPF2_ADDR" -b ${4}M" > logs/UE2_traffic.log &

        # Restarts iperf traffic on URANSIM with half the original traffic and stores the traffic output in "logs/UE1_traffic.log"
        echo "Restarted iperf client on URANSIM (check the logs)."
        kubectl exec -i "$3" -- bash -c "iperf -i 1 -B "$URANSIM1_INT_ADDR" -c "$UPF1_ADDR" -b ${4}M" > logs/UE1_traffic.log
        
        # Wait for iperf traffic to terminate properly
        while true; do 
          # Check if iperf is still running in URANSIM2
          iperf_pid=$(kubectl exec -i "$1" -- bash -c "pgrep iperf")
          if [[ -z "$iperf_pid" ]]; then
            break
          fi       
        done
        sleep 1

        # Terminate the iperf sessions after the traffic ends
        echo "Terminating active iperf sessions..."
        kubectl exec -i "$1" -- pkill iperf
        sleep 1
        echo "Terminated iperf for UE2."
        kubectl exec -i "$2" -- pkill iperf
        sleep 1
        echo "Terminated iperf for UPF2."
        kubectl exec -i "$3" -- pkill iperf
        sleep 1
        echo "Terminated iperf for EU1."

        echo "Traffic end."
}

# Init: iperf installation
echo "Installing iperf on UPF and URANSIM..."
sleep 2

URANSIM1=$(get_pod_name "app=ueransim")
kubectl exec -i "$URANSIM1" -- bash -c "apt update -y && apt install iperf -y && pkill iperf"
sleep 1
echo "Installed iperf on URANSIM."
sleep 1

UPF1=$(get_pod_name "app.kubernetes.io/name=oai-upf")
kubectl exec -i "$UPF1" -- bash -c "apt update -y && apt install iperf -y && pkill iperf"
sleep 1
echo "Installed iperf on UPF."
sleep 1

# Boolean to capture the original throughput value (after 4 iterations)
loop=0

# Run the iperf command on UPF (server) and capture the bandwidth values (in a loop)
echo "Running iperf on pod '$UPF1' for IP '$UPF1_ADDR' in namespace '$NAMESPACE'..."
kubectl exec -n "$NAMESPACE" "$UPF1" -- $COMMAND | while read -r line; do


   echo "$line"
  # Parse lines containing bandwidth values
  if echo "$line" | grep -q "Mbits/sec" ; then
    ((loop++))
    # Check the throuput value on 4th loop
    if [ $loop -eq 4 ]; then
    if [ $TRAFFIC -eq 0 ]; then
     TRAFFIC=1
     # Get the throughput value
     BANDWIDTH=$(echo "$line" | awk '{print $7}')

     # Test if the generated traffic is less than the threshold (15 Mbits)
     if (( $(echo "$BANDWIDTH <= 15" | bc -l) )); then
        # Delete uransim2 and upf2 if they already exist (from previous tests)
        if [[ -n "$(kubectl get pods | grep 'upf2')" ]]; then
          helm uninstall upf2
          sleep 1
          kubectl delete -f oai-ueransim2.yaml
          sleep 1

          # Wait for the termination of and UPF2 and URANSIM2
          while [[ -n "$(kubectl get pods | grep 'ueransim2')" ]]; do
            echo "Waiting for URANSIM2 & UPF2 termination..."
            sleep 2
          done
          echo "Deleted upf2 and uransim2 deployments."
        fi

        echo "All thoughput value goes from UERANSIM1 to UPF1 (original setup)."
     else
      # Test if uransim2 and upf2 already exist (from previous tests)
      if [[ -n "$(kubectl get pods | grep 'upf2')" ]]; then
        echo "upf2 and uransim2 already deployed."
        # Recover UEs pod names
        URANSIM2=$(get_pod_name "app=ueransim2")
        URANSIM1=$(get_pod_name "app=ueransim")
        # Stop iperf client in EU1
        kubectl exec -i "$URANSIM1" -- pkill iperf &
        sleep 1
        # Recover UPFs pod names
        UPF2=$(get_pod_name "app.kubernetes.io/name=oai-upf2")
        UPF1=$(get_pod_name "app.kubernetes.io/name=oai-upf")
        # Divide traffic by half
        HALF_TRAFFIC=$(echo "$BANDWIDTH / 2" | bc -l)
        HALF_TRAFFIC=$(printf "%.0f" $HALF_TRAFFIC)
        echo "New traffic rate: $HALF_TRAFFIC"

        # Start the iperf traffic between UPFs and URANSIMs with half the original throughput
        start_traffic $URANSIM2 $UPF2 $URANSIM1 $HALF_TRAFFIC
        sleep 1

      else
        # Recover UEs pod names
        URANSIM1=$(get_pod_name "app=ueransim")
        # Stop iperf client in EU1
        kubectl exec -i "$URANSIM1" -- pkill iperf &
        sleep 1
        # Recover UPFs pod names
        UPF1=$(get_pod_name "app.kubernetes.io/name=oai-upf")
        # Divide traffic by half
        HALF_TRAFFIC=$(echo "$BANDWIDTH / 2" | bc -l)
        HALF_TRAFFIC=$(printf "%.0f" $HALF_TRAFFIC)
        echo "New traffic rate: $HALF_TRAFFIC"

        # Deploy UPF2 and URANSIM2 with helm and kubectl
        echo "Deploying uransim2 and upf2..."
        helm install upf2 oai-5g-core/oai-upf2
        sleep 3
        echo "Deployed upf2."
        kubectl apply -f oai-ueransim2.yaml
        sleep 3
        UE2_DEP=0
        while [ $UE2_DEP -eq 0 ]; do
                echo "Waiting for UE2 deployment..."
                sleep 1
                if kubectl get pods | grep "ueransim2" | grep "1/1"; then
                        UE2_DEP=1
                        echo "Deployed UE2."
                fi
        done
        sleep 2
        echo "Deployed upf2 and uransim2."
        kubectl get pods
        sleep 1

        URANSIM2=$(get_pod_name "app=ueransim2")
        UPF2=$(get_pod_name "app.kubernetes.io/name=oai-upf2")

        # Install iperf on UPF2 and URANSIM2
        echo "Installing iperf on URANSIM2..."
        kubectl exec -i "$URANSIM2" -- bash -c "apt update -y && apt install iperf -y"
        echo "Installed iperf on URANSIM2."
        sleep 1
        echo "Installing iperf on UPF2..."
        kubectl exec -i "$UPF2" -- bash -c "apt update -y && apt install iperf -y"
        echo "Installed iperf on UPF2."
        sleep 1

        # Start the ne iperf traffic between UPFs and URANSIMs with half the original throughput
        start_traffic $URANSIM2 $UPF2 $URANSIM1 $HALF_TRAFFIC
        sleep 1
      fi
     fi
    fi
    fi
  else
    loop=0
    TRAFFIC=0
  fi
done
