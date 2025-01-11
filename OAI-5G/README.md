# Dynamic Scaling of UPF in 5G Networks Based on Traffic

## Contact

For help and information for this project refer to this email : Sokratis.Christakis@lip6.fr 

## Overview

In this project you are asked to deploy a fully-operational 5G network using OpenAirInterface(OAI) and Kubernetes. Using Kubernetes means that your different network functions will run as independent containers(Docker) within a microservices environment provided by Kubernetes. The goal of this project is to observe the throughput that the UPF is forwarding. Based on that, you are asked to scale the number of UPF instances that deal with these throughput values.

## Getting Started


Clone this repository in your VM 36 (ssh cell@132.227.122.36) to access the files that we have already prepared for you:
```
ssh cell@132.227.122.36
https://github.com/schristakis/5G-UPF-Scaling-Project.git
```
Go into the directory and execute the following command to initialize kubernetes cluster and depedencies. !!!WAIT UNITL THE SCRIPT IS DONE!!:
```
bash init.sh
```
After this script finishes continue by installing helm with the following command:
```
bash get_helm.sh
```


The first step is to deploy the 5G Core Network.

Go inside the the folder that you have just cloned and study the files and more specifically the folder oai-5g-core and oai-ueransim.yaml.

- In this project you will have to deploy the 5G Core funtions **in this specific order** : mysql(Database), NRF, UDR, UDM, AUSF, AMF, SMF, UPF.


```
cd 5g-amf-scaling/oai-5g-core
```
In order to deploy each function you have to execute the following command for each core network function:

```
helm install {network_function_name} {path_of_network_function}
```
For example if you want to deploy the sql database  and then the NRF, UDR you execute:

```
helm install mysql mysql/
helm install nrf oai-nrf/
helm install udr oai-udr/
...
```
It is very important that every after helm command you execute: kubectl get pods in order to see that the respective network function is running, before going to the next one.

In order to uninstall something with helm you execute the following command:
```
helm uninstall {function_name}  ## e.g. helm uninstall udr
```

Afer you deployed all the network functions mentioned above you will be able to connect the UE to the 5G network by executing:

```
kubectl apply -f oai-ueransim.yaml
```

In order to uninstall something with kubectl you execute the following command:
```
kubectl delete -f oai-ueransim.yaml 
```

In order to see if the UE has actually subscribed and received an ip you will have to enter the UE container:

```
kubectl get pods # In order to find the name of the ue_container_name (should look something like this: ueransim-746f446df9-t4sgh)
kubectl exec -ti {ue_container_name} -- bash
```

If everything went well you should be inside the UE container and if you execute ifconfig you should see the following interface:
```
uesimtun0: flags=369<UP,POINTOPOINT,NOTRAILERS,RUNNING,PROMISC>  mtu 1400
        inet 12.1.1.2  netmask 255.255.255.255  destination 12.1.1.2
        inet6 fe80::73e2:e6e6:c3a:3d17  prefixlen 64  scopeid 0x20<link>
        unspec 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00  txqueuelen 500  (UNSPEC)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 12  bytes 688 (688.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

If not, something went wrong. If yes, execute the following command to make sure you have connectivity to the internet through your 5G network:
```
ping -I uesimtun0 8.8.8.8
```


If the ping command works, it means that you have successfully deployed a 5G network and connected a UE to it.

**Extra:** Since you are dealing with throughput, check that iperf works as well:

Enter the UPF container using the following command:
```
kubectl exec -ti {upf_container_name} -- bash       #(get the name again with executing kubectl get nodes)
iperf -s -i 1 -B 12.1.1.*    ## Server (the tun0(12.1.1.*) ip should be visible if you execute ifconfig in the UPF container)
```

Then, enter the UE(client) container and execute:
```
kubectl exec -ti {ue_container_name} -- bash        #(get the name again with executing kubectl get nodes)
iperf -s -i 1 -B 12.1.1.* -c {IP_UPF_FROM_BEFORE} -b 10M        ## Client (the uesimtun0(12.1.1.*) ip should be visible if you execute ifconfig in the UE container)
```
**Caution: Do not test iperf with over 100M because the link will drop and then you will have to recreate the 5G network. Also, use iperf and not iperf3**

## Project goal

As previously mentioned you will have to extend this architecture to manually scale the number of UPFs in the network based on throughput values. The throughput values you will have to use in this project are located in the throughput_values.txt file. Originally  your network will have only one UPF function, but if the throughput is getting higher you will have to scale the UPF deployment to deal with evolving throughput demands. This means that you will deploy a 2nd UPF2 (oai-upf2/) and split the current throughput to the two availabe UPFs.

Hint: You will have to generate traffic from the UE to the UPF based on the file values(throughput_values.txt). Then you will have to develop a script that will measure the throughput that the UPF forwards (you should "hear" the tun0 interface in the UPF) and take action to manually deploy/undeploy the 2nd UPF2 deployment based on this value that you will retrieve.

The scaling should work as follows:

1) If throughput <= 15 Mpbs:
   - All thoughput value goes from UERANSIM1 to UPF1 (Original setup)

2) If throughput > 15:
   - Your script will deploy a 2nd UPF2(oai-upf2) and deploy a 2nd UERANSIM2(oai-ueransim.yaml) as well.
   - UERANSIM1 will generate traffic to the original UPF but half of the thoughput value
   - The other half throughput will be generated from UERANSIM2 to UPF2
