# Kubernetes on Azure using Terraform

This project aims to show a simple example of how you can setup a fully featured k8s cluster on Azure using terraform. 

In the repo we have two templates. The first deploys K8s with Log Analytics Container Monitoring configured and nothing else. The second is deploys commonly used services like managed Postgres, Redis and monitoring (via Azure Log Analytics) to jump start your work. 

## Using 

### Tooling

- Terraform
- Azure CLI
- Community Kubernetes provider [v1.0.7](https://github.com/sl1pm4t/terraform-provider-kubernetes/releases/tag/v1.0.7-custom)

*Note*: Currently the Hashicorp maintained k8s provider is missing some k8s resource types, such as Daemon-Sets, luckily there is a fork maintained with these additional resources. In future, once the [hashicorp provider is updated](https://github.com/terraform-providers/terraform-provider-kubernetes/pull/101), this requirement can be dropped. 

### Running

1. Login to the Azure CLI `az login`
2. Clone this repository and `cd` into the directory
2. Create a service principal for `az ad sp create-for-rbac --skip-assignment` [How-to here](https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal#pre-create-a-new-sp)
3. Create a `varaibles.tfvars` file and add your service principal `clientid` and `clientsecret` as variables. Also add an ssh key and username for logging into k8s agent nodes.

```hcl
client_id = "2f61810e-7f8d-49fd-8c0e-c4f9e7151f9f"

client_secret = "57f8b670-012d-42b2-a0f8-c3dd17e239ad"

linux_admin_username = ""

linux_admin_ssh_publickey = "ssh-rsa AAAasdfasdc2EasdfasdfAAABAQC+b42lMQef/l5D8c7kcNZNf6m37bdfITpUVcfT7trFT/UAWAjym5rxda0PwdkasdfasdfasdfasdfVspDGCYWvHpa3M9UMM6cgdlq+R4ISif4W04yeOmjkRR5j9pcasdfasdfasdfW6PJcgw7IyWIWSONYCSNK6Tk5Yki3N+nAvIxU34+YxPTOpRw42w1AcuorsomethinglikethisnO15SGqFhNagUP/wV/18fvwENt3hsukiBmZ21aP8YqoFWuBg3 james@something"

```
5. Download the Kuberentes provider by running `boostrap_linux.sh` (or mac, windows)
4. Run `terraform init` then `terraform plan` to see what will be created... finally if it looks good run `terraform apply` to create your cluster

## Notes/FAQ

1. Why haven't you used `modules` to organize the template? We'd suggest using them but to keep things simple and easy readable for those new to terraform we haven't included them. 
 

