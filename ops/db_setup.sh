set -e

PG_USER="postgres"
DB_NAME="sentinelrisk_db"
ST_USER="sentinelrisk_user"
ST_USER_PASSWORD="SentinelRisk_123"


# Create role (idempotent)
sudo -u "$PG_USER" psql -c "DO \$\$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$ST_USER') THEN
    CREATE USER $ST_USER WITH PASSWORD '$ST_USER_PASSWORD';
  END IF;
END \$\$;"

# Create database (idempotent)
sudo -u "$PG_USER" psql -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" \
  | grep -q 1 || sudo -u "$PG_USER" psql -c "CREATE DATABASE $DB_NAME OWNER $ST_USER;"

# Grant privileges on the database
sudo -u "$PG_USER" psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $ST_USER;"

# Connect to the database and grant schema privileges
sudo -u "$PG_USER" psql -d "$DB_NAME" -c "GRANT USAGE, CREATE ON SCHEMA public TO $ST_USER;"
sudo -u "$PG_USER" psql -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $ST_USER;"
sudo -u "$PG_USER" psql -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $ST_USER;"
sudo -u "$PG_USER" psql -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO $ST_USER;"

# Enable pgvector extension
sudo -u "$PG_USER" psql -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS vector;"

echo "Database setup completed successfully."
