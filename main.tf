module "jenkins" {
  source  = "terraform-aws-modules/ec2-instance/aws"              //using modules from marketplace

  name = "jenkins"

  instance_type          = "t3.small"
  vpc_security_group_ids = ["sg-0fea5e49e962e81c9"]             #replace your SG
  subnet_id = "subnet-0ea509ad4cba242d7"                        #replace your Subnet
  ami = data.aws_ami.ami_info.id
  user_data = file("jenkins.sh")               //Installing the required packages using shell script file
  tags = {
    Name = "jenkins"
  }

  # Define the root volume size and type
  root_block_device = [
    {
      volume_size = 50                           # Size of the root volume in GB
      volume_type = "gp3"                        # General Purpose SSD (you can change it if needed)
      delete_on_termination = true               # Automatically delete the volume when the instance is terminated
    }
  ]
}

module "jenkins_agent" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-agent"

  instance_type          = "t3.small"
  vpc_security_group_ids = ["sg-0fea5e49e962e81c9"]
  subnet_id = "subnet-0ea509ad4cba242d7"
  ami = data.aws_ami.ami_info.id
  user_data = file("jenkins-agent.sh")      //Installing the required packages using shell script file
  tags = {
    Name = "jenkins-agent"
  }

  root_block_device = [
    {
      volume_size = 50                       # Size of the root volume in GB
      volume_type = "gp3"                    # General Purpose SSD (you can change it if needed)
      delete_on_termination = true           # Automatically delete the volume when the instance is terminated
    }
  ]
}

module "records" {                  //Creating namespace records using module
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = var.zone_name

  records = [
    {
      name    = "jenkins"                                       //public records
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins.public_ip                //getting pub IP record from Jenkins EC2
      ]
      allow_overwrite = true
    },
    {
      name    = "jenkins-agent"                                     //Private records
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins_agent.private_ip             //Getting Private IP Record from Jenkins-agent EC2
      ]
      allow_overwrite = true
    }
  ]

}