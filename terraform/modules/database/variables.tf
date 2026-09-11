variable "db_subnet_a_id" {
  description = "Database subnet A ID"
  type        = string
}

variable "db_subnet_b_id" {
  description = "Database subnet B ID"
  type        = string
}

variable "database_sg_id" {
  description = "Security group ID for the database"
  type        = string
}

variable "db_name" {
  description = "Initial PostgreSQL database name"
  type        = string
}

variable "db_username" {
  description = "Master database username"
  type        = string
}

variable "db_password" {
  description = "Master database password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated database storage in GiB"
  type        = number
  default     = 20
}