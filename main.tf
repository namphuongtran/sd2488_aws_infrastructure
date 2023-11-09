resource "aws_resourcegroups_group" "rg" {
  name = "rg-pisharp"

  resource_query {
    query = <<JSON
    {
      "ResourceTypeFilters": [
        "AWS::AllSupported"
      ],
      "TagFilters": [{
          "Key": "ApplicationName",
          "Values": ["${var.application}"]
        }
      ]
    }
  JSON
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "vpc-pisharp-dev-use1"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
  public_subnets  = ["10.0.64.0/19", "10.0.96.0/19"]

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.default_tags) 
}

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "19.17.2"

#   cluster_name    = "eks-pisharp-dev-use1"
#   cluster_version = "1.28"

#   cluster_endpoint_private_access = true
#   cluster_endpoint_public_access  = true

#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnets

#   enable_irsa = true

#   eks_managed_node_group_defaults = {
#     disk_size = 50
#   }

#   eks_managed_node_groups = {
#     general = {
#       desired_size = 1
#       min_size     = 1
#       max_size     = 10

#       labels = {
#         role = "general"
#       }

#       instance_types = ["t3.small"]
#       capacity_type  = "ON_DEMAND"
#     }

#     spot = {
#       desired_size = 1
#       min_size     = 1
#       max_size     = 10

#       labels = {
#         role = "spot"
#       }

#       taints = [{
#         key    = "market"
#         value  = "spot"
#         effect = "NO_SCHEDULE"
#       }]

#       instance_types = ["t3.micro"]
#       capacity_type  = "SPOT"
#     }
#   }

#   manage_aws_auth_configmap = true
#   aws_auth_roles = [
#     {
#       rolearn  = module.eks_admins_iam_role.iam_role_arn
#       username = module.eks_admins_iam_role.iam_role_name
#       groups   = ["system:masters"]
#     },
#   ]

#    tags = merge(var.default_tags,{
#     Service = "eks-pisharp-dev-use1"
#   }) 
# }

# module "allow_eks_access_iam_policy" {
#   source  = "terraform-aws-modules/iam/aws/modules/iam-policy"
#   version = "5.30.0"

#   name          = "eks-access"
#   create_policy = true

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "eks:DescribeCluster",
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#     ]
#   })
# }


# module "eks_admins_iam_role" {
#   source  = "terraform-aws-modules/iam/aws/modules/iam-assumable-role"
#   version = "5.30.0"

#   role_name         = "eks-admin"
#   create_role       = true
#   role_requires_mfa = false

#   custom_role_policy_arns = [module.allow_eks_access_iam_policy.arn]

#   trusted_role_arns = [
#     "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
#   ]
# }


# module "user1_iam_user" {
#   source  = "terraform-aws-modules/iam/aws/modules/iam-user"
#   version = "5.30.0"

#   name                          = "user1"
#   create_iam_access_key         = false
#   create_iam_user_login_profile = false

#   force_destroy = true
# }

# module "allow_assume_eks_admins_iam_policy" {
#   source  = "terraform-aws-modules/iam/aws/modules/iam-policy"
#   version = "5.30.0"

#   name          = "admin-role"
#   create_policy = true

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "sts:AssumeRole",
#         ]
#         Effect   = "Allow"
#         Resource = module.eks_admins_iam_role.iam_role_arn
#       },
#     ]
#   })
# }

# module "eks_admins_iam_group" {
#   source  = "terraform-aws-modules/iam/aws/modules/iam-group-with-policies"
#   version = "5.30.0"

#   name                              = "admin-group"
#   attach_iam_self_management_policy = false
#   create_group                      = true
#   group_users                       = [module.user1_iam_user.iam_user_name]
#   custom_group_policy_arns          = [module.allow_assume_eks_admins_iam_policy.arn]
# }

# # https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2009
# data "aws_eks_cluster" "default" {
#   name = module.eks.cluster_name
# }

# data "aws_eks_cluster_auth" "default" {
#   name = module.eks.cluster_name
# }

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.default.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
#   # token                  = data.aws_eks_cluster_auth.default.token

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.default.id]
#     command     = "aws"
#   }
# }

# AWS EC2 Security Group Terraform Module
# Security Group for Public Bastion Host
module "public_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "pubsg-pisharp-dev-use1"
  description = "Security group with SSH port open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = module.vpc.vpc_id
  # Ingress Rules & CIDR Block  
  ingress_rules = ["ssh-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  # Egress Rule - all-all open
  egress_rules = ["all-all"]
  tags = merge(var.default_tags) 
}

# AWS EC2 Security Group Terraform Module
# Security Group for Private EC2 Instances
module "private_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "prisg-pisharp-dev-use1"
  description = "Security group with HTTP & SSH ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = module.vpc.vpc_id
  ingress_rules = ["ssh-tcp", "http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules = ["all-all"]
  tags = merge(var.default_tags) 
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  version = "2.0.2"
  key_name           = var.instance_keypair
  create_private_key = true
  tags = merge(var.default_tags,{
    "Name": "kp-pisharp-dev-use1"
  })  
}



# Get latest AMI ID for Amazon Linux2 OS
data "aws_ami" "amzlinux2" {
  most_recent = true
  owners = [ "amazon" ]
  filter {
    name = "name"
    values = [ "amzn2-ami-hvm-*-gp2" ]
  }
  filter {
    name = "root-device-type"
    values = [ "ebs" ]
  }
  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }
  filter {
    name = "architecture"
    values = [ "x86_64" ]
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"
  name = "ec2-pisharp-dev-use1"

  instance_type          = "t2.micro"
  key_name               = var.instance_keypair
  monitoring             = true
  vpc_security_group_ids = [module.public_sg.security_group_id]
  subnet_id              = element(module.vpc.private_subnets, 0)
  ami = data.aws_ami.amzlinux2.id 
  tags = merge(var.default_tags) 
}

# Create a Null Resource and Provisioners
# resource "null_resource" "this" {
#   depends_on = [module.ec2_instance ]
#   # Connection Block for Provisioners to connect to EC2 Instance
#   connection {
#     type = "ssh"
#     host = aws_eip.bastion_eip.public_ip
#     user = "ec2-user"
#     password = ""
#     private_key = file("private-key/terraform-key.pem")
#   } 

#  # Copies the terraform-key.pem file to /tmp/terraform-key.pem
#   provisioner "file" {
#     source      = "private-key/terraform-key.pem"
#     destination = "/tmp/terraform-key.pem"
#   }  

# # Using remote-exec provisioner fix the private key permissions on Bastion Host
#   provisioner "remote-exec" {
#     inline = [
#       "sudo chmod 400 /tmp/terraform-key.pem"
#     ]
#   }  
#   # local-exec provisioner (Creation-Time Provisioner - Triggered during Create Resource)
#   provisioner "local-exec" {
#     command = "echo VPC created on `date` and VPC ID: ${module.vpc.vpc_id} >> creation-time-vpc-id.txt"
#     working_dir = "local-exec-output-files/"
#     #on_failure = continue
#   }
# # ## Local Exec Provisioner:  local-exec provisioner (Destroy-Time Provisioner - Triggered during deletion of Resource)
# #   provisioner "local-exec" {
# #     command = "echo Destroy time prov `date` >> destroy-time-prov.txt"
# #     working_dir = "local-exec-output-files/"
# #     when = destroy
# #     #on_failure = continue
# #   }    
# }

# Create Elastic IP for Bastion Host
# Resource - depends_on Meta-Argument
resource "aws_eip" "bastion_eip" {
  depends_on = [module.ec2_instance, module.vpc]
  instance =  module.ec2_instance.id
  domain   = "vpc"
  tags = merge(var.default_tags,{
    "Name" = "eip-pisharp-dev-use1"
  })  
}
data "aws_caller_identity" "current" {}

# module "ecr" {
#   source = "terraform-aws-modules/ecr/aws"
#   version = "1.6.0"
#   repository_name = "ecr-pisharp-dev-use1"
#   create_lifecycle_policy           = true
#   repository_read_write_access_arns = [data.aws_caller_identity.current.arn]
#   repository_lifecycle_policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1,
#         description  = "Keep last 30 images",
#         selection = {
#           tagStatus     = "tagged",
#           tagPrefixList = ["v"],
#           countType     = "imageCountMoreThan",
#           countNumber   = 30
#         },
#         action = {
#           type = "expire"
#         }
#       }
#     ]
#   })
#   repository_force_delete = true
#   tags = merge(var.default_tags,{
#     Name = "ecr-pisharp-dev-use1"
#   }) 
# }
