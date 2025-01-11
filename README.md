# 5G-UPF-Scaling Project

## About

This is a small project for the **Cellular Networks (CELL)** module at **Sorbonne Université**. The project focuses on **5G-UPF Scaling** using the following technologies:

- **OAI-5G**: OpenAirInterface for 5G core and RAN.
- **Helm**: A Kubernetes package manager for deploying and managing configurations.
- **Kubernetes**: Orchestrating containerized services.
- **UERANSIM**: Simulating User Equipment (UE) and RAN for testing 5G networks.

The objective of this project is to demonstrate dynamic scaling of the User Plane Function (UPF) within a 5G Core Network.

## Features

- Deployment of 5G Core components with OAI-5G.
- Simulation of UEs and RAN using UERANSIM.
- Dynamic scaling of UPFs based on traffic demands.
- Integration with Helm charts for configuration management.
- Orchestration and management using Kubernetes.

## Requirements

Before you begin, ensure you have the following installed:

- Docker
- Kubernetes (Minikube, k3s, or a full Kubernetes cluster)
- Helm
- UERANSIM
- Git

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/5g-upf-scaling.git
   cd 5g-upf-scaling
  ```
