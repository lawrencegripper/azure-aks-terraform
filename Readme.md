# Kubernetes on Azure using Terraform

[![Build Status](https://travis-ci.org/lawrencegripper/azure-aks-terraform.svg?branch=master)](https://travis-ci.org/lawrencegripper/azure-aks-terraform)

This project aims to show a simple example of how you can setup a fully featured k8s cluster on Azure using terraform. 

## What does it create? 

The `main.tf` deploys a [`resourcegroup`](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-overview) in which an [`aks cluster`](https://docs.microsoft.com/en-us/azure/aks/), [`log analytics workspace`](https://docs.microsoft.com/en-us/azure/log-analytics/), [`managed redis cache`](https://docs.microsoft.com/en-us/azure/redis-cache/) and a [`container monitoring`](https://docs.microsoft.com/en-us/azure/log-analytics/log-analytics-containers) solution are added.

Then the connection details from the `redis` and the `log analytics workspace` are injected into the Kuberentes cluster as `Secrets` and a `Deamonset` is created to host the `container monitoring solution agent`. 

## Using 

### Required Tooling

- Terraform
- Azure CLI
- Community Kubernetes provider [v1.0.7](https://github.com/sl1pm4t/terraform-provider-kubernetes/releases/tag/v1.0.7-custom)

*Note*: Currently the Hashicorp maintained k8s provider is missing some k8s resource types, such as Daemon-Sets, luckily there is a fork maintained with these additional resources. In future, once the [hashicorp provider is updated](https://github.com/terraform-providers/terraform-provider-kubernetes/pull/101), this requirement can be dropped. 

### Running

1. Login to the Azure CLI `az login`
2. Clone this repository and `cd` into the directory
3. Create a `varaibles.tfvars` file and add an ssh key and username for logging into k8s agent nodes.

```hcl
linux_admin_username = ""

linux_admin_ssh_publickey = "ssh-rsa AAAasdfasdc2EasdfasdfAAABAQC+b42lMQef/l5D8c7kcNZNf6m37bdfITpUVcfakerFT/UAWAjym5rxda0PwdkasdfasdfasdfasdfVspDGCYWvHpa3M9UMM6cgdlq+R4ISif4W04yeOmjkRR5j9pcasdfasdfasdfW6PJcgw7IyWIWSONYCSNK6Tk5Yki3N+nAvIxU34+YxPTOpRw42w1AcuorsomethinglikethisnO15SGqFhNagUP/wV/18fvwENt3hsukiBmZ21aP8YqoFWuBg3 james@something"

```
5. Download the Kuberentes provider by running `boostrap_linux.sh` (or mac, windows)
4. Run `terraform init` then `terraform plan -var-file=variables.tfvars` to see what will be created... finally if it looks good run `terraform apply -var-file=variables.tfvars` to create your cluster

## Notes/FAQ

1. ~~Why haven't you used `modules` to organize the template? We'd suggest using them but to keep things simple, and easy readable for those new to Terraform, we haven't included them.~~ I changed my mind on this

2. I receive the error `Error: kubernetes_daemonset.container_agent: Provider doesn't support resource: kubernetes_daemonset`: Delete the `.terraform` folder from the directory then make sure you have downloaded the community edition of the kubernetes provider and it is named correctly stored in the current directory. In the root dir run `rm -r .terraform` then rerun the correct bootstrap script. 
 
3. I receive the error `* provider.azurerm: No valid (unexpired) Azure CLI Auth Tokens found. Please run az login.`: Run any `az` command which talks to Azure and it will update the token. For example run `az group list` then retry the Terraform command. 

