#!/bin/bash

# Edit the path to match the files location
OAI_CORE_PATH=OAI-5G/oai-5g-core

echo "uninstalling 5G network..."

cd $OAI_CORE_PATH

helm uninstall mysql
sleep 1
helm uninstall amf
sleep 1
helm uninstall ausf
sleep 1
helm uninstall nrf
sleep 1
helm uninstall smf
sleep 1
helm uninstall traffic-server
sleep 1
helm uninstall udm
sleep 1
helm uninstall udr
sleep 1
helm uninstall upf
sleep 1
if kubectl get pods | grep "upf2"; then
        helm uninstall upf2
        sleep 1
fi

cd ..
kubectl delete -f oai-ueransim.yaml
sleep 1
if kubectl get pods | grep "ueransim2"; then
        kubectl delete -f oai-ueransim2.yaml
        sleep 1
fi

echo "deleted 5G network."
