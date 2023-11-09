variable "default_tags" {
  default     = {
    OpsTeam                = "MSP-Terraform"
    Owner                  = "Nam Phuong Tran"
    Criticality            = "High"
    OpsCommitment          = "Workload Operations"
    Environment            = "dev"
    ApplicationName        = "pisharp"
    Description            = "Managed by Terraform"
  }
  description = "The default project tags"
  type        = map(string)
}


variable "description" {
  type        = string
  description = "The description of the tags"
  default     = "Managed by Terraform"
}

variable "region" {
  type        = string
  description = "the region that resource will be deployed"
  default     = "us-east-1" #"West Europe"
}

variable "region_short" {
  type        = string
  description = "the short name for the location"
  default     = "ue1" #"weu"
}

variable "application" {
  type        = string
  description = "Team accountable for day-to-day operations."
  default     = "pisharp"
}

variable "ops_team" {
  type = string
  default = "msp-terraform"
}

variable "owner" {
  type        = string
  description = "Owner of the application, workload, or service."
  default     = "Nam Phuong Tran"
}

variable "business_criticality" {
  type        = string
  description = "Business impact of the resource or supported workload."
  default     = "high"
}

variable "ops_commitment" {
  type        = string
  description = "Level of operations support provided for this workload or resource."
  default     = "workload operations"
}

variable "environment" {
  type        = string
  description = "Deployment environment of the application, workload, or service. That are dev, test, uat and hotfix"
  default = "dev"
  }
# AWS EC2 Instance Type
variable "instance_type" {
  description = "EC2 Instance Type"
  type = string
  default = "t3.micro"  
}

# AWS EC2 Instance Key Pair
variable "instance_keypair" {
  description = "AWS EC2 Key pair that need to be associated with EC2 Instance"
  type = string
  default = "terraform-key"
}