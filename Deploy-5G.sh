#!/bin/bash

isDeployed=0

echo "Deploying 5G network..."
sleep 2

cd oai-5g-core

helm install mysql mysql/
while [ $isDeployed -eq 0 ]; do
        if kubectl get pods | grep "mysql" | grep "1/1"; then
                isDeployed=1
        fi
done
sleep 1
isDeployed=0

helm install amf oai-amf/
while [ $isDeployed -eq 0 ]; do
        if kubectl get pods | grep "amf" | grep "1/1"; then
                isDeployed=1
        fi
done
sleep 1
isDeployed=0

helm install ausf oai-ausf/
while [ $isDeployed -eq 0 ]; do
        if kubectl get pods | grep "ausf" | grep "1/1"; then
                isDeployed=1
        fi
done
sleep 1
isDeployed=0

helm install nrf oai-nrf/
while [ $isDeployed -eq 0 ]; do
        if kubectl get pods | grep "nrf" | grep "2/2"; then
                isDeployed=1
        fi
done
sleep 1
isDeployed=0

helm install smf oai-smf/
while [ $isDeployed -eq 0 ]; do
        if kubectl get pods | grep "smf" | grep "1/1"; then
                isDeployed=1
        fi
done
sleep 1
isDeployed=0

helm install traffic-server oai-traffic-server/
while [ $isDeployed -eq 0 ]; do
        if kubectl get pods | grep "traffic-server" | grep "1/1"; then
                isDeployed=1
        fi
done
sleep 1
isDeployed=0

helm install udm oai-udm/
while [ $isDeployed -eq 0 ]; do
        if kubectl get pods | grep "udm" | grep "1/1"; then
                isDeployed=1
        fi
done
sleep 1
isDeployed=0

helm install udr oai-udr/
while [ $isDeployed -eq 0 ]; do
        if kubectl get pods | grep "udr" | grep "1/1"; then
                isDeployed=1
        fi
done
sleep 1
isDeployed=0

helm install upf oai-upf/
while [ $isDeployed -eq 0 ]; do
        if kubectl get pods | grep "upf" | grep "1/1"; then
                isDeployed=1
        fi
done
sleep 1

cd ..
kubectl apply -f oai-ueransim.yaml
sleep 1

echo "deployed 5G network."