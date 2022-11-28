# Creates Docdb Cluster

resource "aws_docdb_cluster" "docdb" {
  cluster_identifier      = "roboshop-${var.ENV}"
  engine                  = "docdb"
  master_username         = "admin1"
  master_password         = "roboshop1"
  skip_final_snapshot     = false # True only during lab in prod, we will ytake a snapshot and that time this will be true
}

# Creates subnet group

resource "aws_docdb_subnet_group" "default" {
  name       = "roboshop-${var.ENV}"
  subnet_ids = [aws_subnet.frontend.id, aws_subnet.backend.id]

  tags = {
    Name = "My docdb subnet group"
  }
}