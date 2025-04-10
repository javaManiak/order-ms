provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "kafka_sg" {
  name        = "kafka-sg"
  description = "Allow Kafka and Zookeeper access"
  vpc_id      = "vpc-0047b825c1915174e" # replace with your actual VPC ID

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # allow from microservices only, restrict for prod
  }

  ingress {
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Zookeeper port
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # terminal connection
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "kafka_server" {
  ami           = "ami-084568db4383264d4" # Ubuntu 24.04 LTS AMI for us-east-1 (change if region differs)
  instance_type = "t2.medium"
  key_name      = "kafka_keypair" # replace with your key (can create one in the AWS and use it)
  subnet_id     = "subnet-0b6b44a1da630b110" # replace with your subnet
  # security_groups = [aws_security_group.kafka_sg.name]   # this is not right
  vpc_security_group_ids = [aws_security_group.kafka_sg.id]  # changed it to this one (working now)


  tags = {
    Name = "kafka-server"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install openjdk-17-jdk wget net-tools -y

              # Add Kafka user (optional)
              useradd kafka -m

              # Download Kafka
              wget https://downloads.apache.org/kafka/3.7.0/kafka_2.13-3.7.0.tgz
              tar -xzf kafka_2.13-3.7.0.tgz
              mv kafka_2.13-3.7.0 /opt/kafka

              # Update config (optional: set advertised.listeners to private IP)
              PRIVATE_IP=$(hostname -I | awk '{print $1}')
              sed -i "/^#advertised.listeners=/a advertised.listeners=PLAINTEXT://$PRIVATE_IP:9092" /opt/kafka/config/server.properties

              # Start Zookeeper
              nohup /opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties > /tmp/zookeeper.log 2>&1 &

              # Wait for Zookeeper to start
              sleep 10

              # Start Kafka
              nohup /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties > /tmp/kafka.log 2>&1 &
            EOF
}
