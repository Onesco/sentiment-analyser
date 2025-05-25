resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "google_sql_database_instance" "postgres" {
  name             = var.name
  region           = var.region
  database_version = var.database_version

  settings {
    tier = var.tier

    ip_configuration {
      
      ipv4_enabled    = false
      private_network = var.private_network
    }
  }
  deletion_protection = var.deletion_protection
  depends_on = [var.private_vpc_connection]
}

resource "google_sql_database" "default_db" {
  name     = var.db_name
  instance = google_sql_database_instance.postgres.name
  depends_on = [ google_sql_database_instance.postgres ]
}

resource "google_sql_user" "app_user" {
  name     = var.db_user
  instance = google_sql_database_instance.postgres.name
  password_wo  = random_password.db_password.result
  depends_on = [ google_sql_database_instance.postgres, random_password.db_password ]
}
