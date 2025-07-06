# Install EKS firsrt in prod env, cd into argocd folder

```terraform init```

```terraform plan -var-file="terraform.tfvars"```

```terraform apply --auto-approve -var-file="terraform.tfvars" ```


# set context on your eks cluster (edit)
```aws eks update-kubeconfig --region ca-central-1 --name tsp-cluster-prod```

# if you have different cluster or context
```kubectl config current-context```
```kubectl config get-contexts```
```kubectl config use-context <your-cluster-name>```
# e.g
```kubectl config use-context arn:aws:eks:us-east-1:123456789012:cluster/my-cluster```


# Then try 

```kubectl get nodes```

# to ensure argocd is working with valid cluster IP or LB and pods are running 

```kubectl get svc -n argocd``
```kubectl get pods -n argocd``` 

# if login in through localhost 

``` kubectl port-forward svc/argocd-server -n argocd 8080:443 ```

# argocd password ausername : admin 
#to get password 

```kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode && echo```
# aP5Obpilsjpf9jjF