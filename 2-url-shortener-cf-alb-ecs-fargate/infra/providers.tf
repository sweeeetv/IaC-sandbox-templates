terraform {
    required_version = ">= 1.10.0" //  the minimum Terraform CLI version that can run this config.
    required_providers{
        aws ={
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
    backend "azurerm" { //no need to create azurerm for this section.
        resource_group_name = "rg-terraform-state"
        storage_account_name = "tfstatepersonalxgao"
        container_name = "tfstate"
        key = "temp-url-shortener"
    }
    //use s3 for tf states:
    # backend "s3" {
    #     bucket         = "your-tfstate-bucket"
    #     key            = "url-shortener/terraform.tfstate"
    #     region         = "ap-southeast-2"
    #     dynamodb_table = "terraform-locks"   # for state locking
    # }
}
provider "aws" { //without alias -> default global
    region = "ap-southeast-2"
}
provider "aws" {
    alias = "us_east_1"
    region = "us-east-1"
}

//------------------ ----------------------//
# 1. break the least of the tf files' blob.
# az storage blob lease break --account-name tfstatepersonalxgao --container-name tfstate --blob-name temp-url-shortener --auth-mode login