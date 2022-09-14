# Kubernetes (OpenShift) and example application deployment
Once you have built your application you may want to deploy it.
Kubernetes is one way to achieve this. In the `demo-app`-folder you can find some example files for deploying a web application inside kubernetes.
Either apply the files with manually with `oc`/`kubectl` or use a tool like [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) and point it towards your git-repository. ArgoCD then syncs your cluster with the state defined by the yaml files in the git-repository.

Be aware that the `route.yaml` is defined as a OpenShift Route resource. If you use vanilla Kubernetes, you'll need to define a Ingress resource instead.
These assets are ment as an example how you can configure your application, they are by no means something you should just copy blindly.

To get web traffic into a container in OpenShift you need a deployment with a pod that can receive traffic. Once your deployment is deployed, you need to connect a service. This gives other pods inside your namespace/project the ability to reach your application by the service name. However, a service is not enough for external traffic. For that you need a OpenShift Route or a Kubernetes Ingress. If you do not specify `.spec.host`, you will be assigned a name based on route name + project name + cluster apps url.

## Sealed Secrets
Using a tool like ArgoCD to manage your configuration is awesome. However, you will soon see a problem when it comes to storing secrets. We've all learned that storing any kind of secret inside a code repository is a very bad practice from a security perspective. This is the reason tools like [SealedSecrets](https://github.com/bitnami-labs/sealed-secrets) from Bitnami exists.

This tool uses asymmetric encryption to be able to encrypt your secrets with a public key (this happens when you use the cli tool `kubeseal`).
The tool requires you to be connected to your cluster and have the correct project/namespace selected. Encryption is based on namespace, so once a secret has been encrypted against one namespace, it cannot be decrypted in another.

Once encrypted, only the private key can decrypt these secrets. This private key is stored inside your OpenShift/Kubernetes-cluster and should not be retrievable by normal users. Encryption occurs automatically when you apply a SealedSecret inside a OpenShift/Kubernetes-installation that has the SealedSecrets operator installed.

This makes the SealedSecrets that the tool creates perfectly safe to store inside your git repository. For my gitops-repositories, I usually store a `.gitignore` that includes `**/applied/`. By doing this, you can structure your configurations like:
```
demo-app/
    applied/
        mysecret.yaml
    sealed-mysecret.yaml
```
This way, anything you store inside `applied`-folder will never be commited to the git repository, while the sealed secret is stored outside the `applied`-folder.

Example command for sealing secrets:
```bash
kubeseal --controller-name=sealed-secrets-controller --controller-namespace=sealed-secrets -o yaml < applied/mysecret.yaml > secret-mysecret.yaml
```
Your SealedSecret operator may be stored in a different namespace with a different name. Modify the command as needed.