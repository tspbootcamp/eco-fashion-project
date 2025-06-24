terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

#to select  env
#to initialize and deploy per env
# terraform init
# terraform workspace select dev
# terraform plan -var-file="env/dev.tfvars"
# terraform apply -var-file="env/dev.tfvars"