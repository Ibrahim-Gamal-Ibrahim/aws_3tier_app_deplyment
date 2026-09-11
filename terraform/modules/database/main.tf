resource "aws_db_subnet_group" "main" {
  name = "app-db-subnet-group"

  subnet_ids = [
    var.db_subnet_a_id,
    var.db_subnet_b_id
  ]

  tags = {
    Name        = "app-db-subnet-group"
    Environment = "dev"
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "app-postgres-db"

  engine         = "postgres"
  instance_class = var.db_instance_class

  allocated_storage = var.allocated_storage
  storage_type       = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [
    var.database_sg_id
  ]

  publicly_accessible = false

  skip_final_snapshot = true #make terraform destory easy without requiring a final RDS snapshot.

  backup_retention_period = 7

  deletion_protection = false

  multi_az = false

  #multi_az = false and skip_final_snapshot = true 
  #reduce cost and make repeated destroy/recreate easier. In production, those choices would normally be different.

  tags = {
    Name        = "app-postgres-db"
    Environment = "dev"
  }
}