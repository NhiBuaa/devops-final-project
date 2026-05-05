variable "ssh_ec2" {
  description = "ec2 key pair"
  type        = string
}

variable "member_public_keys" {
  type        = list(string)
  description = "List of Public Keys for team members"
}