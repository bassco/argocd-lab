# argocd lab

This is a walkthrough of an initial argocd installation that installs an app-of-apps solution.

It will be used test the uninstall of CRDs from a cluster where multiple argocd instances were deployed, with each chart installing CrDs. This causes issues during CRD upgrades as the other instances want to flip-flop the CRD versions - lovely!

See the [deps.sh](deps.sh) script for installing the microk8s environment.

This repo uses [asdf](https://github.com/asdf-vm/asdf-vm) and direnv.

## Initial bootstrapping

With the _microk8s_ instance installed and _kubectl_ access, it's time to start the lab.

Set the following hostnames in _`/etc/hosts`_

```shell
127.0.0.1 argocd.example.com argocd-tooling.example.com guestbook.example.com
```

### Add Argo CD

```shell
kubectl kustomize --enable-helm infra/argocd | kubectl apply -f -
```

Get Argo CD admin secret

```shell
export argocd_admin_password=$(kubectl -n argocd get secret argocd-initial-admin-secret -ojson | jq -r ' .data.password | @base64d')
```

Apply app-of-apps

```shell
kubectl apply -k apps
export argocd_tooling_admin_password=$(kubectl -n argocd-tooling get secret argocd-initial-admin-secret -ojson | jq -r ' .data.password | @base64d')
```

You should be able to visit the following URLs:

1. http://argocd.example.com with `admin:${argocd_admin_password}` credentials
1. http://argocd-tooling.example.com with `admin:${argocd_tooling_admin_password}` credentials
1. http://book.example.com - the guestbook test application

## research accreditation

[gitops-with-gitlab-argocd-renovate](https://www.augmentedmind.de/2021/12/26/gitops-with-gitlab-argocd-renovate/)
[argocd-kustomize-with-helm](https://blog.stonegarden.dev/articles/2023/09/argocd-kustomize-with-helm/)
[mini-homelab](https://gitlab.com/vehagn/mini-homelab)

## analysis

Setting the tooling instance to "uninstall" CRDS was a no-op (could be due to the helm versions used).

In order to test a catastrophic scenario - the Applications CRD was forcefully removed, with dire consequences.

### breaking namespaces

When one of the three CRDs are removed by force deleting, a cascade of events takes place. The argo and argocd-tooling instances are uninstalled and the applications enter a zombie state due to finalizers metadata. This needs to be cleared for the rest of the CRDS and the namespaces to be cleaning removed.

Because the argocd instances are removed - their admin passwords will be reset and ALL projects, clusters, repos and secrets will be removed too.

How does this apply to cross-cluster applications that are installed via these instances? Another area of discovery...

```shell

kubectl delete crd applications.argoproj.io --force --wait=false # uninstalls both argocd instances
# to free up the namespaces and remove the zombie applications you need to patch the finalizers
kubectl api-resources --verbs=list --namespaced -o name | \\n   xargs -n 1 kubectl get --show-kind \\n   --ignore-not-found -n argocd

# patch the applications that were the output of the previous command
kubectl patch 'application/argocd' --type=json --patch='[ { "op": "remove", "path": "/metadata/finalizers" } ]' -n argocd
kubectl patch 'application/argocd' --type=json --patch='[ { "op": "remove", "path": "/metadata/finalizers" } ]' -n argocd

# verify that the resources have now been freed and the CRDs are no longer present
kubectl api-resources|grep argocd # should return no output

# create the argocd instance and get the admin password
kubectl kustomize --enable-helm infra/argocd|kubectl apply -f -

# install the infra applications that will sync from github
kubectl -n get secret argocd-initial-admin-secret -ojson | jq -r ' .data.password | @base64d'

# get the argo-tooling admin password
kubectl -n argocd-tooling get secret argocd-initial-admin-secret -ojson | jq -r ' .data.password | @base64d'

```

### the guestbook application

The guestbook application that was manually created with the following CLI command was unaffected when forcefully removing the Application CRD. This is a mystery as to why this occurred.

The commands that were run to install the application are preserved below.

```shell
kubectl create ns guestbook
kubectl -n argocd get secret argocd-initial-admin-secret -ojson | jq -r ' .data.password | @base64d'
argocd login argocd.example.com --grpc-web
argocd context
argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace guestbook
kubectl get pods -n guestbook

```
