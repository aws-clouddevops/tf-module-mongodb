 # Creates Docdb Cluster

resource "aws_docdb_cluster" "docdb" {
  cluster_identifier      = "roboshop-${var.ENV}"
   engine                  = "docdb"
  master_username         = "admin1"
  master_password         = "roboshop1"
  skip_final_snapshot     = true # True only during lab in prod, we will take a snapshot and that time this will be False
  db_subnet_group_name    = aws_docdb_subnet_group.docdb.name
  vpc_security_group_ids  = [aws_security_group.allow_docdb.id]
}

 resource "null_resource" "mongodb-schema" {
   depends_on = [aws_db_instance.docdb]
  
    provisioner "local-exec" {
     command = <<EOF
    cd /tmp/
    curl -s -L -o /tmp/mongodb.zip "https://github.com/stans-robot-project/mongodb/archive/main.zip"   unzip mysql-main
    wget https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem
    unzip -o mongodb.zip
    cd mongodb-main
    mongo --ssl --host ${aws_docdb_cluster.docdb.endpoint}:27017 --sslCAFile /tmp/rds-combined-ca-bundle.pem --username admin1 --password roboshop1 < catalogue.js
    mongo --ssl --host ${aws_docdb_cluster.docdb.endpoint}:27017 --sslCAFile /tmp/rds-combined-ca-bundle.pem --username admin1 --password roboshop1 < users.js
   EOF
   }
 }

# Creates subnet group

resource "aws_docdb_subnet_group" "docdb" {
  name       = "roboshop-mongo-${var.ENV}"
  subnet_ids =  data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNET_IDS

  tags = {
    Name = "My docdb subnet group"
  }
}

# Creates DocDB cluster instance and adds then to the cluster

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = 1
  identifier         = "roboshop-${var.ENV}"
  cluster_identifier = aws_docdb_cluster.docdb.id
  instance_class     = "db.t3.medium"
}

# Creates Security group for DocumentDB

 resource "aws_security_group" "allow_docdb" {
   name        = "roboshop-docdb-${var.ENV}"
   description = "roboshop-docdb-${var.ENV}"
   vpc_id      = data.terraform_remote_state.vpc.outputs.VPC_ID

   ingress {
     description      = "Allow Docdb Connection from default vpc"
     from_port        = 27017
     to_port          = 27017
     protocol         = "tcp"
     cidr_blocks      = [data.terraform_remote_state.vpc.outputs.DEFAULT_VPC_CIDR]
   }

   ingress {
     description      = "Allow docdb Connection from Private vpc"
     from_port        = 3306
     to_port          = 3306
     protocol         = "tcp"
     cidr_blocks      = [data.terraform_remote_state.vpc.outputs.VPC_CIDR]
   }
  
   egress {
     from_port        = 0
     to_port          = 0
     protocol         = "-1"
     cidr_blocks      = ["0.0.0.0/0"]
     ipv6_cidr_blocks = ["::/0"]
   }
     tags = {
     Name = "roboshop-docdb-sg-${var.ENV}"
   }
 }
# resource "aws_docdb_cluster" "default" {
#   cluster_identifier = "docdb-cluster-demo"
#   availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
#   master_username    = "foo"
#   master_password    = "barbut8chars"
# }