Repro:

1. Create a copy of the `variables.example.tfvars` to `variables.private.tfvars` file 
2. Set a valid service principal in the file
4. Run `terraform apply -var-file variables.private.tfvars -var node_sku=standard_ds2_v2` and observe the error
5. Terrafom will attempt to create the cluster for around 3mins before you will see `azurerm_kubernetes_cluster.aks: Still creating... (10s elapsed)`

```
azurerm_kubernetes_cluster.aks: Code="InvalidTemplate" Message="Provisioning of resource(s) for container service aks-885 in resource group temp-akstf6 failed. Message: Deployment template validation failed: 'The provided value 'standard_ds3_v2' for the template parameter 'agentpoolVMSize' at line '1' and column '2004' is not valid. The parameter value is not part of the allowed value(s): 'Standard_A0.....'.. Details: "
```
6. Check the portal and see the following message for the cluster `This container service is in a failed state. Click here to open a support request`