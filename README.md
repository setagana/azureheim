# AzureHeim

This repository contains the necessary Terraform script(s) to create a dedicated server for Valheim in Microsoft Azure, running in Azure Container Instances.

Based on [the fantastic work of Lukas Lösche's Valheim docker image](https://github.com/lloesche/valheim-server-docker).

## Prerequisites

These docs will assume you're running a Windows 10 machine, Linux users should be able to adapt them without too much difficulty.

1. An Azure account set up and ready to use. [Official getting started info](https://docs.microsoft.com/en-us/learn/modules/create-an-azure-account/)
2. The Azure CLI installed on your machine. [Official installation guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (make sure to log in with `az login` once installed)
3. Terraform installed on your machine. There are two options for the installation:
    1. Get the latest version from [the Terraform downloads page](https://www.terraform.io/downloads.html) and unzip it in a location that's part of your `PATH` environment variable.
    2. Install it via [Chocolatey](https://chocolatey.org/). First install Chocolatey, then open your command prompt and enter `choco install terraform`

## Authenticating To Azure From Terraform

Terraform gains access to create resources in your Azure account through a service principal - think of this as a virtual user account with permissions to create resources for you in Azure.

### Create The Service Principal

Open your command prompt and run the following command to get the ID of your Azure Subscription:

```
az account list --query [*].[name,id]
```

Copy the GUID for your subscription, such as `308358d5-db96-46e0-b463-15d33c2690d6`.

Then, create a service principal in your subscription with the command below. You'll need to swap the subscription ID in this example for the ID you got from the command above.

```
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/308358d5-db96-46e0-b463-15d33c2690d6" -n ValheimTerraform
```

The output contains several pieces of information you'll need for the next step.

### Set Environment Variables

If you're unfamiliar with setting environment variables in Windows, [here's a quick guide](https://www.computerhope.com/issues/ch000549.htm#windows10). Rather than changing the `PATH` variable at step 6 of that guide, you'll be adding New variables in the top half of the Environment Variables window (User variables).

Create the following environment variables:

1. Azure subscription ID
    * Variable name: ARM_SUBSCRIPTION_ID
    * Variable value: {{ Set this to the ID (without quotes) you got from the `az account list` command }}
2. Service principal application ID:
    * Variable name: ARM_CLIENT_ID
    * Variable value: {{ The appId value (without quotes) from the `az ad sp create-for-rbac` command output }}
3. Service principal password:
    * Variable name: ARM_CLIENT_SECRET
    * Variable value: {{ The password value (without quotes) from the `az ad sp create-for-rbac` command output }}
4. Azure Active Directory tenant
    * Variable name: ARM_TENANT_ID
    * Variable value: {{ The tenant value (without quotes) from the `az ad sp create-for-rbac` command output }}

## Fill Terraform Config File

Open the `config.tfvars` file in this directory and fill the variables according to the comments contained there.

## Copy Your Existing World (Optional)

If you want to migrate an existing world to your new Valheim server, please refer to [this doc](./docs/existing-world.md).

## Apply The Terraform Script

Now you have everything you need to apply the Terraform script and create your server. Simply open a command prompt to this folder (containing `main.tf`) and enter:

```
terraform apply -var-file=config.tfvars
```

You will first be asked to enter a password for your new server.

After that, Terraform will list all the resources that will be created in your Azure account to run your server. Simply enter `yes` to continue.