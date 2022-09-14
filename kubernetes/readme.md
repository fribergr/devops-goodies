# Kubernetes (OpenShift) and example application deployment
Once you have built your application you may want to deploy it.
Kubernetes is one way to achieve this. In the `demo-app`-folder you can find some example files for deploying a web application inside kubernetes.
Either apply the files with manually with `oc`/`kubectl` or use a tool like [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) and point it towards your git-repository. ArgoCD then syncs your cluster with the state defined by the yaml files in the git-repository.

Be aware that the `route.yaml` is defined as a OpenShift Route resource. If you use vanilla Kubernetes, you'll need to define a Ingress resource instead.
These assets are ment as an example how you can configure your application, they are by no means something you should just copy blindly.

To get web traffic into a container in OpenShift you need a deployment with a pod that can receive traffic. Once your deployment is deployed, you need to connect a service. This gives other pods inside your namespace/project the ability to reach your application by the service name. However, a service is not enough for external traffic. For that you need a OpenShift Route or a Kubernetes Ingress. If you do not specify `.spec.host`, you will be assigned a name based on route name + project name + cluster apps url.