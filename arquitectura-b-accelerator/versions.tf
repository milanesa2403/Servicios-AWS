terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  alias  = "primaria"
  region = var.region_primaria
  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  alias  = "secundaria"
  region = var.region_secundaria
  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  alias  = "global"
  region = "us-west-2"
  default_tags {
    tags = local.tags
  }
}
