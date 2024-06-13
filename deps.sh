#!/usr/bin/env bash

sudo apt-get install \
	stow \
	python3-venv \
	direnv \
	tree || true
tools="argocd fd fzf helm helmfile java jq krew kubectl kustomize nodejs rg ripgrep rust stern zoxide"
for tool in $tools; do
	asdf plugin add $tool || true
done
asdf install
exit 0
sudo snap install microk8s --classic
mkdir ~/.kube
sudo usermod -a -G microk8s $USER && sudo chown -R $USER ~/.kube
newgrp microk8s
microk8s status
microk8s enable hostpath-storage
microk8s enable ingress
microk8s enable minio
microk8s enable registry
microk8s config >~/.kube/config && chmod 0600 ~/.kube/config
# Test kubectl access
microk8s kubectl get pods -n ingress
microk8s kubectl get pods -n container-registry
kubectl kustomize --enable-helm infra/argocd | kubectl apply -f -
curl -l argocd.example.com
argocd admin initial-password -n argocd && echo
argocd login argocd.example.com --grpc-web
#kubectl config set-context --current --namespace=argocd
#argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default
#argocd admin initial-password -n argocd-tooling && echo
#argocd login argocd-tooling.example.com --grpc-web
argocd context
#kubectl create ns guestbook
#argocd app create guestbook --grpc-web --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace guestbook
