#!/bin/bash

# Set the Kubernetes context if needed
# kubectl config use-context your-context

# Get a list of deployments
deployments=$(kubectl get deployments -A -o json)

# Extract information from the JSON output
deployment_data=$(echo "$deployments" | jq -r '.items[] | {name: .metadata.name, replicas: .spec.replicas, limits: .spec.template.spec.containers[].resources.limits, requests: .spec.template.spec.containers[].resources.requests} | @base64')

# Print information
echo "Deployments:"
echo "----------------------------------------------------------------------------------------------"
echo "Name | Replicas | Resource Limits (CPU/Memory) | Resource Requests (CPU/Memory)"
echo "----------------------------------------------------------------------------------------------"
echo "$deployment_data" | while read -r line; do
    decoded_line=$(echo "$line" | base64 --decode)
    name=$(echo "$decoded_line" | jq -r '.name')
    replicas=$(echo "$decoded_line" | jq -r '.replicas')
    limits_cpu=$(echo "$decoded_line" | jq -r '.limits.cpu // "N/A"')
    limits_memory=$(echo "$decoded_line" | jq -r '.limits.memory // "N/A"')
    requests_cpu=$(echo "$decoded_line" | jq -r '.requests.cpu // "N/A"')
    requests_memory=$(echo "$decoded_line" | jq -r '.requests.memory // "N/A"')

    echo "$name | $replicas | Limits: CPU=$limits_cpu, Memory=$limits_memory | Requests: CPU=$requests_cpu, Memory=$requests_memory"
done
