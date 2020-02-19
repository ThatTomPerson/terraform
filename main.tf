provider "aws" {
  profile    = "default"
  region     = "ap-southeast-2"
}


data "aws_ami" "amzn2" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-2.0.*"]
  }
}

data "aws_vpc" "vpc" {
  id = "vpc-0dfed99c0bdcd1c67"
}
resource "aws_ebs_volume" "persistent" {
  availability_zone = "ap-southeast-2a"
  size = 100
  type = "gp2"

  tags = { 
    Name = "factorio"
  }
}

resource "aws_launch_template" "factorio" {
  name_prefix   = "factorio"
  image_id      = data.aws_ami.amzn2.id
  instance_type = "m3.medium"
  key_name = "id_rsa"

  iam_instance_profile {
    arn = aws_iam_instance_profile.factorio.arn
  }

  placement {
    availability_zone = "ap-southeast-2a"
  }

  user_data = base64encode(templatefile("userdata.sh", {
    ebs_volume = aws_ebs_volume.persistent.id
  }))
}

resource "aws_iam_instance_profile" "factorio" {
  name = "factorio"
  role = aws_iam_role.factorio.name
}

resource "aws_iam_role" "factorio" {
  name = "factorio"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

data "aws_iam_policy_document" "attach_factorio_ebs_volume" {
  statement {
    sid = "1"

    actions = [
      "ec2:AttachVolume"
    ]

    resources = [
      "arn:aws:ec2:ap-southeast-2:921614132363:instance/*",
      aws_ebs_volume.persistent.arn
    ]
  }
}

resource "aws_iam_policy" "attach_factorio_ebs_volume" {
  name   = "attach_factorio_ebs_volume"
  path   = "/"
  policy = data.aws_iam_policy_document.attach_factorio_ebs_volume.json
}

resource "aws_iam_role_policy_attachment" "attach_factorio_ebs_volume" {
  role       = aws_iam_role.factorio.name
  policy_arn = aws_iam_policy.attach_factorio_ebs_volume.arn
}


# Request a spot instance at $0.03
resource "aws_autoscaling_group" "factorio" {
  desired_capacity   = 1
  max_size           = 1
  min_size           = 0

  launch_template {
    id      = aws_launch_template.factorio.id
    version = "$Latest"
  }
}