data "aws_instances" "web" {
  filter {
    name   = "tag:Name"
    values = ["web-server-*"]  # Or use specific name tags
  }
  filter {
    name   = "tag:ENV"
    values = ["dev"]  # Or use specific name tags
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instances" "app" {
  filter {
    name   = "tag:Name"
    values = ["app-server-*"]  # Or use specific name tags
  }
  filter {
    name   = "tag:ENV"
    values = ["dev"]  # Or use specific name tags
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}