You will need to create a .tfvars file in each terraform directory and add the following to each respectively:

`dev_terraform/terraform.tfvars`
```
aws_profile = "dev-profile-name-here"
```

`prod_terraform/terraform.tfvars`
```
aws_profile = "prod-profile-name-here"
```

`test_terraform/terraform.tfvars`
```
aws_profile = "test-profile-name-here"
```


## Quick defintion of outputs and variables in terraform

### Variables

- Purpose: Variables are used to pass data into a module or configuration.
 
- Direction: Variables are "inputs" to a module.

- Defined In: variables.tf file (or directly in main.tf if you prefer not to use variables.tf).

### Outputs

- Purpose: Outputs are used to expose data from a module to the parent module (or root configuration).

- Direction: Outputs are "outputs" from a module.

- Defined In: outputs.tf file (or directly in main.tf if you prefer not to use outputs.tf).


__In your root configuration (main.tf), you connect them__
