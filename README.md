# Deployment scripts for microservices project

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

## About

Project is dedicated to making a primitive microservices application.
This repository contains all scripts for CI/CD and deploying system.

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

#### CI/CD
Built using Jenkins. It should NOT be installed as Docker container (e.g. in GKE
environment). The hosting machine must have docker and kubectl installed. If you
are going to use docker images from your own docker registry account, then
you need to correct hardcoded values (e.g. 'anshelen/microservices-backend') in
kubernetes and jenkins files.

#####Setting pipelines:
1. Deploy services in GKE
2. Install Jenkins with plugins:  
   * [Kubernetes Cli](https://plugins.jenkins.io/kubernetes-cli)
   * [Remote File](https://plugins.jenkins.io/remote-file)
3. Call [script](jenkins/jenkins-register.sh). It will create service account 
for Jenkins and print a token to access kubernetes cluster
4. Create global credentials with the following ID's:
   *  'github-creds' - username/password for git repository
   *  'dockerhub-creds' - username/password for docker registry
   *  'kubernetes-creds' - secret with 'secret text' type containing generated
   token
5. Create Jenkins global environment variable CLUSTER_URL with url of your
kubernetes master node. You can get it with command:
    ```
    kubectl cluster-info
    ```  
6. Create multibranch pipelines for both backend and gateway services. In
"Build Configuration" choose to fetch Jenkinsfile using remote file plugin. Set
appropriate script path for each file (e.g. jenkins/Jenkinsfile-backend) and
pick up your git repository. Toggle "Periodically if not otherwise run" in
"Scan Repository Triggers" to scan main repository for changes every a few
minutes.

#####Build steps:
1. Checkout from git
2. Build and compile project in isolated docker environment (jdk image)
3. Test project
4. Compose docker image and push it to docker registry with 'latest' and 
'v$BUILD_NUMBER' tags
5. Trigger kubernetes cluster to use image with the actual 'v$BUILD_NUMBER' tag

## License

This software is licensed under the [BSD License][BSD]. For more information, read the file [LICENSE](LICENSE).

[BSD]: https://opensource.org/licenses/BSD-3-Clause
