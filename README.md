# Deployment scripts for microservices project

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

## About

Project is dedicated to making a primitive microservices application.
This repository contains all scripts for CI/CD and deploying system.

## Create namespace

To create namespace:
```
kubectl create ns msvc-ns
```
To set namespace msvc-ns as default:
```
kubectl config set-context --current --namespace=msvc-ns
```

## Commands without using Helm 3

#### Deploy on Minikube
To deploy system in minikube:
```
kubectl apply -f scripts_minikube/
```
To access endpoint (remove -n flag if you deployed to default namespace):
```
curl $(minikube service gateway --url -n msvc-ns)
```

#### Deploy on Google Kubernetes Engine
I recommend to create cluster of minimum 2 standard nodes (n1-standard-1). It
will give you enough resources to deploy this project with predefined resource
requests and limits.

To deploy system in GKE:
```
kubectl apply -f scripts_gke/
```
To access endpoint:
```
curl $(kubectl get svc gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

#### CI/CD
Built using Jenkins. It should NOT be installed as Docker container (e.g. in GKE
environment). The hosting machine must have docker and kubectl installed. If you
are going to use docker images from your own docker registry account, then
you need to correct hardcoded values (e.g. 'anshelen/microservices-backend') in
kubernetes and jenkins files. Also Jenkins is set to use 'msvc-ns' namespace for
cluster.

##### Setting pipelines:
1. Deploy services in GKE
2. Install Jenkins with plugins:  
   * [Kubernetes Cli](https://plugins.jenkins.io/kubernetes-cli)
   * [Remote File](https://plugins.jenkins.io/remote-file)
3. Call [script](jenkins-kubectl/jenkins-register.sh). It will create service account 
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

##### Build steps:
1. Checkout from git
2. Build and compile project in isolated docker environment (jdk image)
3. Test project
4. Compose docker image and push it to docker registry with 'latest' and 
'v$BUILD_NUMBER' tags
5. Trigger kubernetes cluster to use image with the actual 'v$BUILD_NUMBER' tag

## Commands with using Helm 3

#### Prepare environment (optional)
You can set up namespace and resource quotas with command:
```
kubectl apply -f scripts_env/
```
To call all following commands in created namespace:
```
kubectl config set-context --current --namespace=msvc-ns
```

#### Install chart
To install chart with 'msvc-project' name:
```
helm install msvc-project msvc-chart/
```
Alternatively you can fetch this chart from the helm repository:
https://anshelen.github.io/microservices-deploy/.

Test chart:
```
helm test msvc-project
```

#### Customize deployment
Show available options:
```
helm show values msvc-chart/
```
To upgrade installation:
```
helm upgrade msvc-project msvc-chart/ --set backend.deployment.name=new-name
```
##### Notes:
1. Argument --set can be used multiple times 
2. To keep previously set options use flag --reuse-values
3. You should not modify your cluster using 'kubectl'. All manipulations must
be done through Helm
4. On default gateway service is of LoadBalancer type (gateway.service.type=LoadBalancer).
It is nice for deploy on GKE, but for Minikube it is more suitable to set this
option to ClusterIP or NodePort
5. Horizontal Pod Autoscalers for backend and gateway deployments are disabled
by default. To enable, set backend/gateway.hpa.enabled=true. Keep in mind
that you must provide requests.cpu value for deployment. If you prepared
environment - it is done for you automatically. To enable or change cpu request
manually, set backend/gateway.container.resources.requests.cpu=100m option
6. Be default a service account is created for your deployments. You can
cancel it by specifying serviceAccount.create=false option

#### CI/CD
Setting pipeline using Helm is mostly the same as described above. Differences:
1. Helm 3 should be installed on hosting machine
2. List commands to obtain token for kubernetes credentials (no more need to 
call jenkins/jenkins-register.sh script):
    ```
    helm status msvc-project
    ```
3. Create Jenkins global environment variable HELM_PROJECT with a name of your
helm project (in out case it is 'msvc-project')
4. Jenkinsfiles are placed in 'jenkins-helm' folder
5. If you install helm chart without specifying any options - builds might not
update images due to Helm [bug](https://github.com/helm/helm/issues/7509). To
walkaround, upgrade the project manually for the first time:
```helm upgrade msvc-project msvc-chart/ --set any=null```

## License

This software is licensed under the [BSD License][BSD]. For more information, read the file [LICENSE](LICENSE).

[BSD]: https://opensource.org/licenses/BSD-3-Clause
