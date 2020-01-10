#!/bin/bash

# Create a ServiceAccount named `jenkins-robot` in a given namespace.
kubectl -n msvc-ns create serviceaccount jenkins-robot > /dev/null 2>&1
# The next line gives `jenkins-robot` administator permissions for this namespace.
# * You can make it an admin over all namespaces by creating a `ClusterRoleBinding` instead of a `RoleBinding`.
# * You can also give it different permissions by binding it to a different `(Cluster)Role`.
kubectl -n msvc-ns create rolebinding jenkins-robot-binding --clusterrole=cluster-admin --serviceaccount=msvc-ns:jenkins-robot > /dev/null 2>&1
# Get the name of the token that was automatically generated for the ServiceAccount `jenkins-robot`.
token=$(kubectl -n msvc-ns get serviceaccount jenkins-robot -o go-template --template='{{range .secrets}}{{.name}}{{"\n"}}{{end}}')
# Retrieve the token and decode it using base64.
kubectl -n msvc-ns get secrets "$token" -o go-template --template '{{index .data "token"}}' | base64 -d
echo
