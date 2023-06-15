# Microservice-Development-Flow-Design


How to deploy a react or nodes application.

https://www.youtube.com/watch?v=6-RtA6FlbgQ



https://www.coderrocketfuel.com/articles

https://www.coderrocketfuel.com/article/how-to-deploy-a-next-js-website-to-a-digital-ocean-server



https://www.learnwithjason.dev/blog/deploy-nodejs-ssl-digitalocean



Deploy a NextJs app to DigitalOcean using Github Actions and Docker

https://medium.com/geekculture/deploy-a-nextjs-app-to-digitalocean-using-github-actions-and-docker-db7127bca3aa





How to Deploy Angular, Spring Boot & MySQL on DigitalOcean Kubernetes in 30 mins

https://www.javachinna.com/deploy-angular-spring-boot-mysql-digitalocean-kubernetes/



How to Setup Prometheus Monitoring On Kubernetes Cluster

https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/



Documentation on ffa Erpnext deployment on Kubernetes and Installation of custom-apps(ffa,healthcare and chat)


Jamiu Ejiwumi
Dec 8, 2022
Documentation on deployment of Erpnext on Kubernetes

Here are the exact steps I did.
1. # Create a K8s cluster(EKS,AKS, DOKS or GKe).
In this case I used DOKS, but other K8s clusters should work too. This step is irrelevant to ERPNext installation.

2. # _Install an in-cluster NFS service_ 
The special thing here is to make the storage larger than 8GiB, otherwise ERPNext will complain when claiming PV.

prepare NFS, this NFS has to be slightly larger than 8GiB, or ERPNext will fail to bind the storage
kubectl create namespace nfs
helm repo add nfs-ganesha-server-and-external-provisioner https://kubernetes-sigs.github.io/nfs-ganesha-server-and-external-provisioner 
helm upgrade --install -n nfs in-cluster nfs-ganesha-server-and-external-provisioner/nfs-server-provisioner --set 'storageClass.mountOptions={vers=4.1}' --set persistence.enabled=true --set persistence.size=9Gi
3. # _Install ERPNext****_

Install ERPNext, don't use custom values

kubectl create namespace erpnext
helm repo add frappe https://helm.erpnext.com 
helm upgrade --install frappe-bench --namespace erpnext frappe/erpnext --set persistence.worker.storageClass=nfs
4. Create a site, modify the values.yaml file which you can find in the helm chart.

This is just following up the guide.

clone git@github.com:frappe/helm.git to your local
cd to /helm/erpnext
Create a custom-value.yaml file
copy and paste below:
jobs:
createSite:
enabled: true
siteName: "devapp.ffa.io "
adminPassword: "secret"

NB devapp.ffa.io  domain name must have been set under zone-editor(ffa Domain) as a subdomain in https://parallelscoreprojects.com/(cpanel) 
then,

Save it and Run the following commands:

helm template frappe-bench -n erpnext frappe/erpnext -f custom-values.yaml -s templates/job-create-site.yaml > create-new-site-job.yaml
kubectl apply -f create-new-site-job.yaml -n erpnext
5. Install ingress-nginx

helm install nginx-ingress ingress-nginx/ingress-nginx
6. Create a new ingress to route the traffic from internet

Create a yaml file called ingress.yaml
copy and paste below:
apiVersion: networking.k8s.io/v1 
kind: Ingress
metadata:
name: erp-resource
annotations:
kubernetes.io/ingress.class:  "nginx"
nginx.ingress.kubernetes.io/ssl-redirect:  "false"
spec:
rules:

host: "devapp.ffa.io "
http:
paths:

pathType: Prefix
path: "/"
backend:
service:
name: frappe-bench-erpnext
port:
number: 8080
run kubectl apply -f ingress.yaml -n erpnext

devapp.ffa.io  should be up and running
Screen Shot 2022-12-08 at 8.21.03 PM.png

Now, to install custom-apps
