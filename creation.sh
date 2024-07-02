#!/bin/bash

# Variables
resourceGroup="Resour-needed-01"
aksClusterName="aks-cluster"
acrName="myacrrepo531"
namespace="helm-deploy"

# Create resource group
az group create --name $resourceGroup --location <your-location>

# Create AKS cluster
az aks create --resource-group $resourceGroup --name $aksClusterName --node-count 2 --generate-ssh-keys

# Get AKS credentials
az aks get-credentials --resource-group $resourceGroup --name $aksClusterName

# Create ACR repository
az acr create --resource-group $resourceGroup --name $acrName --sku Basic

# Get ACR login server
acrLoginServer=$(az acr show --name $acrName --resource-group $resourceGroup --query "loginServer" --output tsv)

# Create namespace in AKS cluster
kubectl create namespace $namespace

# Grant AKS access to ACR
az aks update -n $aksClusterName -g $resourceGroup --attach-acr $acrName

# Set ACR credentials as Kubernetes secrets
kubectl create secret docker-registry acr-credentials --namespace $namespace --docker-server=$acrLoginServer --docker-username=<your-acr-username> --docker-password=<your-acr-password> --docker-email=<your-acr-email>

# Install Helm in AKS cluster
kubectl apply -f https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get

# Initialize Helm
helm init --service-account tiller --tiller-namespace $namespace

# Wait for Helm to be ready
kubectl rollout status deployment/tiller-deploy -n $namespace

# Print success message
echo "AKS cluster, ACR repository, and namespace for Helm deployment created successfully!"
