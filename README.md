# 5G-UPF-Scaling Project

## About

This is a small project for the **Cellular Networks (CELL)** module at **Sorbonne Université**. The project focuses on **5G-UPF Scaling** using the following technologies:

- **OAI-5G**: OpenAirInterface for 5G core and RAN.
- **Helm**: A Kubernetes package manager for deploying and managing configurations.
- **Kubernetes**: Orchestrating containerized services.
- **UERANSIM**: Simulating User Equipment (UE) and RAN for testing 5G networks.

The objective of this project is to demonstrate dynamic scaling of the User Plane Function (UPF) within a 5G Core Network with a bash script.

## Features

- Deployment of 5G Core components with OAI-5G.
- Simulation of UEs and RAN using UERANSIM.
- Dynamic scaling of UPFs based on traffic demands.
- Integration with Helm charts for configuration management.
- Orchestration and management using Kubernetes.

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/5g-upf-scaling.git
   cd 5g-upf-scaling
2. Initialize the project:
   ```bash
   cd OAI-5G
   bash init.sh
3. In the same directory, install Helm:
   ```bash
   bash get_helm.sh
4. Deploy the 5G network:
   ```bash
   cd OAI-5G/oai-5g-core
   # For every 5G component:
   helm install {network_function_name} {path_of_network_function}
   # Deploy UERANSIM:
   cd ..
   kubectl apply -f oai-ueransim.yaml
- Alternatively, you can run the **Deploy.sh** script at the root of this project.
- You might need to redeploy your 5G network (manually) if **UERANSIM** doesn't get an IP from the 5G network.

## UPF Auto-Scaling:

In order to scale the UPF instances in your 5G network based on incoming traffic:
1. Open a new terminal at the root of this project.
2. Run the **Scaler.sh** script and wait for it to start an iperf server:
   ```bash
   bash Scaler.sh
3. Open another terminal in the same directory, and access the UERANSIM pod:
   ```bash
   kubectl exec -it {pod_name} -- bash
4. Inside the UERANSIM pod, start an iperf client:
   ```bash
   iperf -i 1 -B {UERANSIM_uesimtun0_addr} -c {UPF_tun0_addr} -t 30 -b 10M

## Limitations

This project was tested (and passed all the throughput tests) in an ideal environment with minimal server overload. If you're deploying this project in an overloaded server you might face the following issues:
- UERANSIM failing to get an IP from the 5G network.
- Failed pings from UERANSIMs and their respective UPFs.
- Connection timeouts with iperf.

## Demo:
- I made a demo video so you can see how the UPF scaling works: https://youtu.be/vMBYiu13dcg
