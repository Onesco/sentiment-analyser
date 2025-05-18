output "instance_connection_name" {
  value = google_sql_database_instance.postgres.connection_name
}

output "db_password" {
  value     = random_password.db_password.result
  sensitive = true
}

output "db_name" {
  value = google_sql_database.default_db.name
}

output "db_host" {
  value = google_sql_database_instance.postgres.private_ip_address
}

output "db_username" {
  value = google_sql_user.app_user.name
}
