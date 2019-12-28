# Deployment scripts for microservices project

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

## About

Project is dedicated to making a primitive microservices application.
In this repository all deployment scripts are collected.

## Commands

#### Minikube
To deploy system in minikube:
```
kubectl apply -f scripts_minikube/
```
To access endpoint:
```
curl $(minikube service gateway --url -n msvc-ns)
```

#### Google Kubernetes Engine
To deploy system in GKE:
```
kubectl apply -f scripts_gke/
```
To access endpoint:
```
curl $(kubectl get svc gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' -n msvc-ns)
```

## License

This software is licensed under the [BSD License][BSD]. For more information, read the file [LICENSE](LICENSE).

[BSD]: https://opensource.org/licenses/BSD-3-Clause
