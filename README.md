Пример кода для поста [Сохранение IP-адреса клиента с при развертывании приложения за балансировщиком нагрузки](https://nikolaymatrosov.ru/2025-03-09-Preserving-client-IP-behind-load-balancers/?utm_source=github&utm_medium=readme&utm_campaign=example)

Run Packer

```bash
export YC_FOLDER_ID=...
export YC_BUILD_SUBNET=...
packer build echo.pkr.hcl
```

Fill `tf/.tfvars` according to `tf/.tfvars.example`

Run Terraform

```bash
cd tf
terraform init
terraform apply -var-file=".tfvars"
```

To get to the VM in the instance group, you will need to use the ssh command from the output of the terraform apply command.

```bash
ssh -A -J ubuntu@$bastion_ip ubuntu@$target_ip
```