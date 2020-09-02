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

## Commands using pure Kubectl

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
kubernetes and jenkins files. Also Jenkins is using 'msvc-ns' namespace in a
cluster. All files are situated in 'jenkins-kubectl' folder.

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
"Build Configuration" choose fetching Jenkinsfile using remote file plugin. Set
appropriate script path for each file (e.g. jenkins-kubectl/Jenkinsfile-backend)
and pick up your git repository. Fields 'Local File' and 'Branch Specifier'
should be left blank. Toggle "Periodically if not otherwise run" in "Scan
Repository Triggers" to scan main repository for changes every a few minutes.

##### Build steps:
1. Checkout from git
2. Build and compile project in isolated docker environment (jdk image)
3. Test project
4. Compose docker image and push it to docker registry with 'latest' and 
'v$BUILD_NUMBER' tags
5. Trigger kubernetes cluster to use image with the actual 'v$BUILD_NUMBER' tag

## Commands using Helm 3

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
Add repository with you chart:
```
helm repo add msvc-repo https://anshelen.github.io/microservices-deploy/
```
Update local repositories data:
```
helm repo update
```
To install chart with 'msvc-project' name:
```
helm install msvc-project msvc-repo/msvc-chart
```
Test chart:
```
helm test msvc-project
```

#### Customize deployment
Show available options:
```
helm show values msvc-repo/msvc-chart
```
To upgrade installation:
```
helm upgrade msvc-project msvc-repo/msvc-chart --set backend.deployment.name=new-name
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
6. By default a service account is created for your deployments. You can
cancel it by specifying serviceAccount.create=false option

#### CI/CD
Setting pipeline using Helm is mostly the same as described above. All files are
located in 'jenkins-helm' folder.
Differences:
1. Helm 3 should be installed on hosting machine and your chart repository
should be added manually (see commands above)
2. List commands to obtain token for kubernetes credentials (no more need to 
call jenkins-kubectl/jenkins-register.sh script):
    ```
    helm status msvc-project
    ```
3. Create Jenkins global environment variable HELM_PROJECT with a name of your
helm project (in out case it is 'msvc-project')
4. If you install helm chart without specifying any options - builds might not
update images due to Helm [bug](https://github.com/helm/helm/issues/7509). To
walkaround, upgrade the project manually for the first time:
```helm upgrade msvc-project msvc-repo/msvc-chart --set any=null```

## CI/CD with packaged Dockerfile
Files with additional 'package' step are collected in 'jenkins' folder. Docker
images are created directly from the tested jar-archives (in above methods they
were created from scratch). It minimizes pipeline time.
Some mandatory global environment variables for Jenkins were added:
  * HELM_CHART - your repo with chart name (e.g. msvc-repo/msvc-chart)
  * CLUSTER_NAMESPACE - Kubernetes cluster namespace
 
## Set up ELK
We will need 3 Google Compute Engine VMs to install 3 Elasticsearch nodes 
(3 master nodes, 2 data nodes), Logstash, Kibana and Nginx proxy. 
As free GCP trial has a quote of 4 nodes, you should install your cluster on one
node (e2-standard-2). All resources must be located in the same zone.

### Steps

1. Cluster can be installed with the following command:
    ```helm
    helm install msvc-project msvc-repo/msvc-chart \
    --set backend.container.resources.requests.cpu=50m \
    --set backend.hpa.enabled=true \
    --set gateway.container.resources.requests.cpu=50m \
    --set gateway.hpa.enabled=true \
    --set secrets.secret=secret
    ```

2. Edit files in [elk](elk) package. Modify all urls like 
'es-1.europe-west1-b.c.sturdy-lore-263019.internal' with your zone and project
id. Template is ```es-*.<zone>.c.<project-id>.internal```.

3. Create two standard persistent disks with 30 GB volume with names 
'elk-data-1' and 'elk-data-2'.

4. Create and add SSH key to your GCP account

5. Create 3 GCE VMs:

    | Instance name | Type | Boot disk capacity | Mounted disk | Enable HTTP traffic |
    |:-------------:|:----:|:------------------:|:------------:|:-------------------:|
    | es-1 | e2-standard-2 | 30 GB | None       | True  |
    | es-2 | e2-medium     | 10 GB | elk-data-1 | False |
    | es-3 | e2-medium     | 10 GB | elk-data-2 | False |
    
6. Format disks if they are just created:
    ```shell script
    scp -i <path-to-ssh-private-key> elk/format_disk.sh <user-name>@<es-2-node-external-ip>:~/
    ssh -i <path-to-ssh-private-key> <user-name>@<es-2-node-external-ip>  
    sh format_disk.sh
    ```
   Repeat is similarly for es-3 node.

7. Install software on all nodes:
    ```shell script
    scp -i <path-to-ssh-private-key> elk/es-1/* <user-name>@<es-1-node-external-ip>:~/
    ssh -i <path-to-ssh-private-key> <user-name>@<es-1-node-external-ip>  
    sh install.sh
    ```
    Repeat is similarly for nodes es-2 and es-3.
    
8. Bootstrap services in es-1 node ```sh bootstrap.sh```. After completion
(!!! its important) bootstrap other nodes.

9. Check ES status:
    ```shell script
    curl http://es-1.<your-zone>.c.<project-id>.internal:9200/_cat/health
    ```
    Status should be green. You can see all nodes: 
    ```shell script
    curl http://es-1.<your-zone>.c.<project-id>.internal:9200/_cat/nodes
    ```
10. Navigate to ```<es-1-node-external-ip>``` and Kibana should be opened. 
In StackManagement -> Index Lifecycle Policies create policy 'gke-logs-policy' 
with the following settings:

    Hot phase
    
    * Enable rollover: true
    * Minimum index size: 5 GB 
    * Maximum age: 3 days
    * Index priority: 100
   
    Warm phase
   
    * Move to warm phase on rollover: false
    * Timing for warm phase: 7 days from rollover
    * Force merge: true
    * Force merge number of segments: 1
    * Index priority: 50
    
    Cold phase
    
    * Timing for cold phase: 21 days from rollover
    * Freeze: true
    * Index priority: 0
    
    Delete phase:
    
    * Timing for delete phase: 30 days from rollover
 
11. In StackManagement -> Index Management -> Index Templates create new legacy 
template:
    
    * Name: gke-logs-template
    * Index pattern: gke-logs*
    * Index settings: 
        ```json
        {
          "index": {
            "lifecycle": {
              "name": "gke-logs-policy",
              "rollover_alias": "gke-logs"
            },
            "number_of_shards": "1",
            "number_of_replicas": "1"
          }
        }
        ```
    * Mappings: load [mapping file](elk/settings/gke-logs-mapping.json) 
    * Dynamic mapping: disable
    * Throw an exception when a document contains an unmapped field: true
    
12. Create initial index. Go to Dev Tools and execute:
    ```
    PUT gke-logs-000001
    {
        "aliases": {
            "gke-logs": {
                "is_write_index": true
            }
        }
    }
    ``` 
    
13. In StackManagement -> Index Patterns create default pattern 'gke-logs*' with
timestamp field '@timestamp'

14. Install filebeat on k8s cluster:
    ```shell script
    kubectl apply -f elk/filebeat-kubernetes.yml
    ```

15. Send request to application, navigate to ```<es-1-node-ip>``` and see logs in
Kibana ('Discover' tab).

## License

This software is licensed under the [BSD License][BSD]. For more information, read the file [LICENSE](LICENSE).

[BSD]: https://opensource.org/licenses/BSD-3-Clause
