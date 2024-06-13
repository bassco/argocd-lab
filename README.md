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

test
