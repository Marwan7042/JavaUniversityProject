#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
container_name="${UNIVERSITY_DB_CONTAINER:-universitydb}"
sa_password="${SA_PASSWORD:-MSSQLpass123}"
db_login_password="${UNIVERSITY_DB_PASSWORD:-UniPass123!}"
schema_src="${project_root}/database/message(1).sql"
seed_src="${project_root}/database/01_Reset_And_Seed_OptionB_Dummy_Data_FIXED (1).sql"

if ! command -v docker >/dev/null 2>&1; then
	echo "Docker is not installed." >&2
	exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -qx "${container_name}"; then
	echo "SQL Server container '${container_name}' is not running on localhost:1433." >&2
	echo "Start it first, then rerun this script." >&2
	exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

schema_tmp="${tmp_dir}/schema-linux.sql"
seed_tmp="${tmp_dir}/seed-wrapper.sql"

awk '
BEGIN {
		replaced = 0
		skipping = 0
}

{
	sub(/\r$/, "", $0)
}

NR == 1 {
		print
		next
}

NR == 2 {
	print
	next
}

!replaced && /^CREATE DATABASE \[UniversityDB\]/ {
		print "IF DB_ID(N'\''UniversityDB'\'') IS NULL"
		print "BEGIN"
		print "    CREATE DATABASE [UniversityDB];"
		print "END"
		print "GO"
		replaced = 1
		skipping = 1
		next
}

skipping {
		if ($0 == "GO") {
				skipping = 0
		}
		next
}

{
		print
}
' "${schema_src}" > "${schema_tmp}"

echo "Updating SQL login..."
docker exec "${container_name}" /opt/mssql-tools18/bin/sqlcmd \
	-S localhost,1433 \
	-U sa \
	-P "${sa_password}" \
	-C \
	-b \
	-l 60 \
	-Q "USE [UniversityDB]; IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'university_user') DROP USER [university_user]; USE [master]; IF EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'university_user') DROP LOGIN [university_user]; CREATE LOGIN [university_user] WITH PASSWORD = '${db_login_password}', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;"

schema_exists="$(docker exec "${container_name}" /opt/mssql-tools18/bin/sqlcmd -S localhost,1433 -U sa -P "${sa_password}" -C -d UniversityDB -h -1 -W -Q "SET NOCOUNT ON; SELECT CASE WHEN OBJECT_ID('dbo.students','U') IS NULL THEN 0 ELSE 1 END" | tr -d '\r[:space:]')"

if [[ "${schema_exists}" == "1" ]]; then
	docker exec "${container_name}" /opt/mssql-tools18/bin/sqlcmd \
		-S localhost,1433 \
		-U sa \
		-P "${sa_password}" \
		-C \
		-b \
		-l 60 \
		-Q "USE [UniversityDB]; IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'university_user') CREATE USER [university_user] FOR LOGIN [university_user] WITH DEFAULT_SCHEMA=[dbo]; IF IS_ROLEMEMBER('db_owner', 'university_user') = 0 ALTER ROLE [db_owner] ADD MEMBER [university_user];"
fi

if [[ "${schema_exists}" != "1" ]]; then
	echo "Creating schema..."
	docker cp "${schema_tmp}" "${container_name}:/tmp/schema-linux.sql"
	docker exec "${container_name}" /opt/mssql-tools18/bin/sqlcmd \
		-S localhost,1433 \
		-U sa \
		-P "${sa_password}" \
		-C \
		-b \
		-l 120 \
		-i /tmp/schema-linux.sql
else
	echo "Schema already exists; skipping schema creation."
fi

echo "Seeding data..."
cat > "${seed_tmp}" <<'EOF'
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
SET ANSI_PADDING ON
GO
SET ANSI_WARNINGS ON
GO
SET ARITHABORT ON
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO
SET NUMERIC_ROUNDABORT OFF
GO
EOF
cat "${seed_src}" >> "${seed_tmp}"
docker cp "${seed_tmp}" "${container_name}:/tmp/seed-wrapper.sql"
docker exec "${container_name}" /opt/mssql-tools18/bin/sqlcmd \
	-S localhost,1433 \
	-U sa \
	-P "${sa_password}" \
	-C \
	-b \
	-l 120 \
	-i /tmp/seed-wrapper.sql

echo "Verifying seed data..."
docker exec "${container_name}" /opt/mssql-tools18/bin/sqlcmd \
	-S localhost,1433 \
	-U sa \
	-P "${sa_password}" \
	-C \
	-d UniversityDB \
	-Q "SELECT COUNT(*) AS student_count FROM dbo.students;"

echo "Local database is ready on localhost:1433."
echo "Run the app on your machine with:"
echo "  cd \"${project_root}\" && mvn javafx:run"
