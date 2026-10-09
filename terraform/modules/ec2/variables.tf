variable "name" {
  description = "Name prefix for the instance and its related resources."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID. Leave null to use the latest Amazon Linux 2023."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC to launch the instance in."
  type        = string
}

variable "subnet_id" {
  description = "Subnet to launch the instance in."
  type        = string
}

variable "associate_public_ip" {
  description = "Give the instance a public IP."
  type        = bool
  default     = false
}

variable "key_name" {
  description = "Optional EC2 key pair name. Not needed if you use SSM Session Manager."
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Root volume size in GiB."
  type        = number
  default     = 20
}

variable "detailed_monitoring" {
  description = "Enable 1-minute CloudWatch metrics."
  type        = bool
  default     = true
}

variable "user_data" {
  description = "Optional user data script."
  type        = string
  default     = null
}

variable "ingress_rules" {
  description = "Inbound rules for the security group."
  type = list(object({
    description = string
    protocol    = string
    from_port   = number
    to_port     = number
    cidr        = string
  }))
  default = []
}

variable "readable_secret_arns" {
  description = "Secrets Manager ARNs the instance is allowed to read."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Resource-specific tags."
  type        = map(string)
  default     = {}
}
