# event-search

## ⚠️ Security Notice

**This repository is for LOCAL DEVELOPMENT & TESTING only.**

All credentials are intentionally simple for ease of use during development:
- Default passwords are provided in `.env` and `.env.example`
- Compose files use environment variables with fallback defaults
- Self-signed TLS certificates are generated at runtime

**For production deployments:**
- Create a `.env` file with **strong, unique passwords** (never commit this file)
- Use proper TLS certificates from a certificate authority
- Implement secrets management (AWS Secrets Manager, HashiCorp Vault, etc.)
- Review and harden security configurations before deployment

**Do NOT commit `.env` file** - it's excluded in `.gitignore`

## Local Development

### Docker Compose Stacks

Eleven separate compose files for different database stacks:

| Stack | File | Services | Memory (Approx) |
|-------|------|----------|-----------------|
| **Version Mix** | `docker-compose.yml` | ES 6/7/8/9 + Kibana, OpenSearch, Easysearch, DynamoDB | ~6 GB |
| **Latest Stack** 🔥 | `docker-compose-latest.yml` | ES 9.4, ES 7.17, OS 3.5, Easysearch, DynamoDB, Mongo 4.0/8.3 | ~3.7 GB |
| **ES TLS Cluster** | `elastic-cluster-tls.yml` | 3-node ES cluster + Kibana (TLS enabled) | ~3 GB |
| **ES Production Cluster** | `elastic-cluster-production.yml` | 11-node ES 9.4 cluster with dedicated roles | ~13 GB |
| **OS Production Cluster** | `opensearch-cluster-production.yml` | 11-node OS + MinIO (Reader/Writer separation) | ~10 GB |
| **SQLKit Core** | `docker-compose-sqlkit-core.yml` | PostgreSQL, MySQL 8.0, MariaDB, SQL Server, TiDB, CockroachDB, ClickHouse | ~3 GB |
| **SQLKit PG Ext** | `docker-compose-sqlkit-pgext.yml` | YugabyteDB, TimescaleDB, OpenGauss, HighGo (+ commented: KingbaseES, GaussDB) | ~2 GB |
| **SQLKit 信创** | `docker-compose-sqlkit-xc.yml` | OceanBase, GBase 8a, XuguDB (+ commented: PolarDB-X, DM8) | ~3 GB |
| **SQLKit Analytics** | `docker-compose-sqlkit-analytics.yml` | Trino, Presto | ~1 GB |
| **SQLKit Enterprise** | `docker-compose-sqlkit-enterprise.yml` | H2 (+ commented: Oracle XE, Db2) | ~0.5 GB |
| **MongoDB** | `docker-compose-mongo.yml` | MongoDB 4/5/6/7/8 + Mongo Express | ~3 GB |

### Setup

**1. Create environment file:**
```bash
# Copy the example file
cp .env.example .env

# Edit .env and set your passwords (at least 6 characters for each)
# IMPORTANT: NEVER commit .env to git
```

**2. Required passwords to set in `.env`:**
- `ELASTIC_PASSWORD` - Elasticsearch admin password
- `KIBANA_PASSWORD` - Kibana system password
- `SEARCH_PASSWORD` - Unified password for Latest Stack
- `OPENSEARCH_ADMIN_PASSWORD` - OpenSearch admin password
- `OPENSEARCH_KIBANA_PASSWORD` - OpenSearch Dashboards password
- `MINIO_ROOT_PASSWORD` - MinIO S3 storage password
- `MYSQL_ROOT_PASSWORD` - MySQL/MariaDB root password
- `MYSQL_PASSWORD` - MySQL application password
- `POSTGRES_PASSWORD` - PostgreSQL/TimescaleDB password
- `SA_PASSWORD` - SQL Server SA password
- `MARIADB_ROOT_PASSWORD` - MariaDB root password
- `MARIADB_PASSWORD` - MariaDB application password
- `CLICKHOUSE_PASSWORD` - ClickHouse password
- `OPENGUASS_PASSWORD` - OpenGauss password
- `HIGHGO_PASSWORD` - HighGo password
- `OCEANBASE_PASSWORD` - OceanBase tenant password
- `OCEANBASE_SYS_PASSWORD` - OceanBase sys password
- `MONGO_EXPRESS_PASSWORD` - Mongo Express web UI password

### Start/Stop Commands

**Start a single stack:**
```bash
# SQLKit stacks
docker compose -f docker-compose-sqlkit-core.yml up -d
docker compose -f docker-compose-sqlkit-pgext.yml up -d
docker compose -f docker-compose-sqlkit-xc.yml up -d
docker compose -f docker-compose-sqlkit-analytics.yml up -d
docker compose -f docker-compose-sqlkit-enterprise.yml up -d

# Other stacks (examples)
docker compose -f docker-compose-latest.yml up -d
docker compose -f docker-compose-mongo.yml up -d
```

**Stop a single stack:**
```bash
docker compose -f docker-compose-sqlkit-core.yml down
```

**Start all stacks (parallel):**
```bash
docker compose up -d && \
docker compose -f docker-compose-latest.yml up -d && \
docker compose -f elastic-cluster-tls.yml up -d && \
docker compose -f elastic-cluster-production.yml up -d && \
docker compose -f opensearch-cluster-production.yml up -d && \
docker compose -f docker-compose-sqlkit-core.yml up -d && \
docker compose -f docker-compose-sqlkit-pgext.yml up -d && \
docker compose -f docker-compose-sqlkit-xc.yml up -d && \
docker compose -f docker-compose-sqlkit-analytics.yml up -d && \
docker compose -f docker-compose-sqlkit-enterprise.yml up -d && \
docker compose -f docker-compose-mongo.yml up -d
```

**Stop all stacks:**
```bash
docker compose down && \
docker compose -f docker-compose-latest.yml down && \
docker compose -f elastic-cluster-tls.yml down && \
docker compose -f elastic-cluster-production.yml down && \
docker compose -f opensearch-cluster-production.yml down && \
docker compose -f docker-compose-sqlkit-core.yml down && \
docker compose -f docker-compose-sqlkit-pgext.yml down && \
docker compose -f docker-compose-sqlkit-xc.yml down && \
docker compose -f docker-compose-sqlkit-analytics.yml down && \
docker compose -f docker-compose-sqlkit-enterprise.yml down && \
docker compose -f docker-compose-mongo.yml down
```

**Stop and remove volumes (clean slate):**
```bash
docker compose down -v && \
docker compose -f docker-compose-latest.yml down -v && \
docker compose -f elastic-cluster-tls.yml down -v && \
docker compose -f elastic-cluster-production.yml down -v && \
docker compose -f opensearch-cluster-production.yml down -v && \
docker compose -f docker-compose-sqlkit-core.yml down -v && \
docker compose -f docker-compose-sqlkit-pgext.yml down -v && \
docker compose -f docker-compose-sqlkit-xc.yml down -v && \
docker compose -f docker-compose-sqlkit-analytics.yml down -v && \
docker compose -f docker-compose-sqlkit-enterprise.yml down -v && \
docker compose -f docker-compose-mongo.yml down -v
```

---

### 🆕 Latest Stack (`docker-compose-latest.yml`)

Lightweight, HTTP-only stack for modern testing. Uses a unified password from `.env` (`SEARCH_PASSWORD`).

**Services & Ports:**
| Service | HTTP URL | User | Password | Memory |
|---------|----------|------|----------|--------|
| Elasticsearch 9.4 | `http://<HOST_IP>:19250` | `elastic` | `$SEARCH_PASSWORD` | ~790 MB |
| Elasticsearch 7.17 | `http://<HOST_IP>:19310` | `elastic` | `$SEARCH_PASSWORD` | ~738 MB |
| OpenSearch 3.5 | `http://<HOST_IP>:19270` | `admin` | `$SEARCH_PASSWORD` | ~868 MB |
| OpenSearch Dashboards | `http://<HOST_IP>:15650` | `admin` | `$SEARCH_PASSWORD` | ~237 MB |
| Easysearch 2.2 | `http://<HOST_IP>:19280` | `admin` | `$SEARCH_PASSWORD` | ~689 MB |
| MongoDB 8.3 | `mongodb://<HOST_IP>:19330` | `admin` | `$SEARCH_PASSWORD` | ~148 MB |
| MongoDB 4.0 | `mongodb://<HOST_IP>:19320` | `admin` | `$SEARCH_PASSWORD` | ~129 MB |
| DynamoDB Local | `http://<HOST_IP>:19290` | AWS SDK (no auth) | - | ~200 MB |

**Total Memory:** ~3.7 GB active, ~5 GB peak.
**Network Access:** All services bind to `0.0.0.0`, accessible from any machine on the local network via `<HOST_IP>`. If you have a firewall, open the ports: `sudo ufw allow 19250,19270,19280,19300,19310,19320,19330,15650/tcp`.

**Quick Test:**
```bash
# Test connectivity from host or another machine
curl http://<HOST_IP>:19250/_cluster/health?pretty
curl -u admin:$SEARCH_PASSWORD http://<HOST_IP>:19270/_cluster/health?pretty

# Local MongoDB test
docker exec latest-mongo-8-3 mongosh --eval "db.adminCommand('ping')"
```

---

### Elasticsearch Stack (No TLS) (`docker-compose.yml`)

**Service Ports Reference:**
| Service | Port | UI Port |
|---------|------|---------|
| Elasticsearch 9 | 19200 | Kibana: 5605 |
| Elasticsearch 8 | 9201 | Kibana: 5602 |
| Elasticsearch 7 | 9202 | Kibana: 15601 |
| Elasticsearch 6 | 9203 | Kibana: 5604 |
| OpenSearch 2.8 | 9204 | Dashboards: 5603 |
| Easysearch | 9205 | - |
| DynamoDB Local | 8000 | - |

### Elasticsearch TLS Cluster (3-node) (`elastic-cluster-tls.yml`)

| Service | Port | Notes |
|---------|------|-------|
| Elasticsearch (es01) | 9200 (configurable via `.env`) | HTTPS with TLS, user: `elastic` |
| Kibana | 5601 (configurable via `.env`) | Connected to TLS cluster |

Configuration via `.env` file:
- `STACK_VERSION` - Elasticsearch/Kibana version (default: 8.2.3)
- `ELASTIC_PASSWORD` - Password for `elastic` user
- `KIBANA_PASSWORD` - Password for `kibana_system` user
- `ES_PORT` / `KIBANA_PORT` - Exposed ports

**Connect to TLS cluster:**
```bash
# Elasticsearch
curl -u elastic:$ELASTIC_PASSWORD https://localhost:9200/_cluster/health

# Kibana UI
open https://localhost:$ES_PORT
# Login: elastic / $ELASTIC_PASSWORD
```

### Elasticsearch Production Cluster (11-node) (`elastic-cluster-production.yml`)

Production-grade cluster with dedicated node roles.

| Node Type | Nodes | JVM Heap | Memory Limit | Role |
|-----------|-------|----------|--------------|------|
| Master | 3 | 512MB | 1GB | Cluster state management |
| Data | 5 | 512MB | 1GB | Shard storage & search |
| Coordinating | 2 | 512MB | 1GB | Request routing & aggregation |
| Ingest | 1 | 512MB | 1GB | Pipeline processing |

**Ports:**
| Service | Port | Notes |
|---------|------|-------|
| Coordinating node 1 | 9220 | Load balanced entry point |
| Coordinating node 2 | 9221 | Load balanced entry point |
| Kibana | 5620 | Web UI |

**Memory footprint:** ~13GB total (requires 16GB+ Docker allocation)

**Connect to production cluster:**
```bash
# Through coordinating node (recommended for clients)
curl -u elastic:$ELASTIC_PASSWORD https://localhost:9220/_cluster/health

# Kibana UI
open https://localhost:5620
# Login: elastic / $ELASTIC_PASSWORD
```

### OpenSearch Production Cluster (11-node + MinIO) (`opensearch-cluster-production.yml`)

Production-grade OpenSearch 3.x cluster with Reader/Writer separation architecture.

**Ports:**
| Service | Port | Notes |
|---------|------|-------|
| Coordinating node 1 | 9230 | Load balanced entry point |
| Coordinating node 2 | 9231 | Load balanced entry point |
| Dashboards | 5630 | Web UI |
| MinIO API | 9000 | S3-compatible storage |
| MinIO Console | 9001 | Web UI |

**Connect to OpenSearch cluster:**
```bash
# Through coordinating node (with auth)
curl -k -u admin:$OPENSEARCH_ADMIN_PASSWORD https://localhost:9230/_cluster/health

# Dashboards UI (with login)
open http://localhost:5630
# Login: admin / $OPENSEARCH_ADMIN_PASSWORD
```

### SQLKit Core Stack (`docker-compose-sqlkit-core.yml`)

Multi-dialect SQL database testing stack. Covers 4 distinct wire protocols (PG wire, MySQL, T-SQL, HTTP/columnar).

**Services & Ports:**
| Service | Version | Port | Wire Protocol | Credentials |
|---------|---------|------|---------------|-------------|
| PostgreSQL | 16 | 5432 | PG wire | user: `sqlkit`, pass: `$POSTGRES_PASSWORD`, db: `sqlkit` |
| MySQL | 8.0 | 3306 | MySQL | user: `sqlkit`, pass: `$MYSQL_PASSWORD`, db: `sqlkit` |
| MariaDB | 11 | 3307 | MySQL-compat | user: `sqlkit`, pass: `$MARIADB_PASSWORD`, db: `sqlkit` |
| TiDB | 8.5 | 4000 | MySQL-compat | user: `root` (no password), db: `test` |
| SQL Server | 2022 | 1433 | T-SQL | user: `sa`, pass: `$SA_PASSWORD`, db: `master` |
| CockroachDB | 24.1 | 26257 | PG wire | no auth (insecure), UI: `http://localhost:18080` |
| ClickHouse | latest | 8123 (HTTP) / 19000 (native) | HTTP/columnar | user: `sqlkit`, pass: `$CLICKHOUSE_PASSWORD`, db: `sqlkit` |

**Total Memory:** ~3 GB active.

**Quick Test:**
```bash
# PostgreSQL
docker exec sqlkit-postgres-16 psql -U sqlkit -d sqlkit -c 'SELECT 1'

# MySQL
docker exec sqlkit-mysql-8 mysql -u sqlkit -p"${MYSQL_PASSWORD}" -e 'SELECT 1'

# TiDB
mysql -h 127.0.0.1 -P 4000 -u root -e 'SELECT 1'

# SQL Server
docker exec sqlkit-sqlserver-2022 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -C -Q 'SELECT 1'

# CockroachDB
docker exec sqlkit-cockroachdb-24 ./cockroach sql --insecure -e 'SELECT 1'

# ClickHouse HTTP
curl -u sqlkit:"${CLICKHOUSE_PASSWORD}" http://localhost:8123?query=SELECT+1

# MariaDB
docker exec sqlkit-mariadb-11 mysql -u sqlkit -p"${MARIADB_PASSWORD}" -e 'SELECT 1'
```

**Embedded databases** (no Docker, handle at test level): SQLite, DuckDB, H2

---

### SQLKit PG Ecosystem Stack (`docker-compose-sqlkit-pgext.yml`)

PG-wire compatible databases. Some (OpenGauss, HighGo) are 信创 domestic.

| Service | Version | Port | Credentials | Notes |
|---------|---------|------|-------------|-------|
| YugabyteDB | latest | 5433 | no auth (insecure) | Distributed PG-wire |
| TimescaleDB | latest-pg16 | 5434 | user: `sqlkit`, pass: `$POSTGRES_PASSWORD`, db: `sqlkit` | PG extension |
| OpenGauss | latest | 5435 | user: `gaussdb`, pass: `$OPENGUASS_PASSWORD` | 信创 PG-based, needs `privileged` |
| HighGo | 6.0.1 | 5866 | user: `highgo`, pass: `$HIGHGO_PASSWORD` | 信创 PG-based, needs `privileged` |

**Commented services** (require manual setup — see compose file):
- **KingbaseES** — download tar from kingbase.com.cn, `docker load`
- **GaussDB** — community image at docker.io/enmotech/gaussdb
- **GBase 8c** — needs systemd + multi-step init inside container
- **UXDB** — no public Docker image

**Quick Test:**
```bash
# YugabyteDB
docker exec sqlkit-yugabyte /home/yugabyte/postgres/bin/pg_isready -h localhost -p 5433

# TimescaleDB
docker exec sqlkit-timescale pg_isready -U sqlkit

# OpenGauss
docker exec sqlkit-opengauss pg_isready -U gaussdb

# HighGo
docker exec sqlkit-highgo psql -U highgo -c 'SELECT 1'
```

---

### SQLKit 信创 Stack (`docker-compose-sqlkit-xc.yml`)

Chinese domestic databases (信创). TiDB is in `sqlkit-core` since it's the most common for daily testing.

| Service | Version | Port | Credentials | Notes |
|---------|---------|------|-------------|-------|
| OceanBase | latest | 2881 | user: `root@test`, pass: `$OCEANBASE_PASSWORD` | MySQL-compat, 2-5 min init |
| GBase 8a | 1.0 | 5258 | user: `root`, pass: `root`, db: `gbase` | MPP analytical |
| XuguDB | 12.9 | 5138 | user: `SYSDBA`, db: `SYSTEM` | Proprietary |

**Commented services** (require manual setup):
- **PolarDB-X** — needs 12GB+ RAM. Image: `polardbx/polardb-x`
- **DM8** — download tar from eco.dameng.com, `docker load`
- **TDSQL** — no Docker image, requires multi-node ansible deployment

**Quick Test:**
```bash
# OceanBase (wait 2-5 min for boot)
docker logs sqlkit-oceanbase 2>&1 | tail -1  # should show "boot success!"
mysql -h 127.0.0.1 -P 2881 -u root@test -p"${OCEANBASE_PASSWORD}" -e 'SELECT 1'

# GBase 8a (default user: root / pass: root)
# docker exec -it sqlkit-gbase8a bash  # explore available tools

# XuguDB
# Use JDBC: jdbc:xugu://localhost:5138/SYSTEM
```

---

### SQLKit Analytics Stack (`docker-compose-sqlkit-analytics.yml`)

Distributed SQL query engines. No auth by default.

| Service | Version | Port | Notes |
|---------|---------|------|-------|
| Trino | latest | 8088 | Web UI: `http://localhost:8088` |
| Presto | latest | 8089 | Similar to Trino, older codebase |

**Quick Test:**
```bash
# Trino
curl -X POST http://localhost:8088/v1/statement -d 'SELECT 1'

# Presto
curl -X POST http://localhost:8089/v1/statement -d 'SELECT 1'
```

---

### SQLKit Enterprise Stack (`docker-compose-sqlkit-enterprise.yml`)

Databases requiring license acceptance or registry login.

| Service | Version | Port | Credentials | Notes |
|---------|---------|------|-------------|-------|
| H2 | latest | 18082 (web) / 19092 (tcp) | user: `sa`, pass: (blank) | Java embedded, server mode |

**Commented services** (require license acceptance):
- **Oracle XE 21c** — `docker login container-registry.oracle.com` + accept license
- **IBM Db2** — `docker login icr.io` + accept license

**Quick Test:**
```bash
# H2 Console
open http://localhost:18082
# JDBC: jdbc:h2:tcp://localhost:19092/mem:test
```

---

### MongoDB Stack (`docker-compose-mongo.yml`)
| Version | Port | Mongo Express | Key Feature |
|---------|------|---------------|-------------|
| 4.4 | 27017 | 8081 | Last stable before wire protocol changes |
| 5.0 | 27018 | 8082 | Time series collections |
| 6.0 | 27019 | 8083 | Change streams enhancement |
| 7.0 | 27020 | 8084 | Queryable encryption |
| 8.0 | 27021 | 8085 | Latest performance updates |

Mongo Express credentials: `admin` / `$MONGO_EXPRESS_PASSWORD`

### Useful Commands

**View running containers:**
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**View logs:**
```bash
docker logs -f latest-es-9-4
docker logs -f os-3-5
```

**Check container health:**
```bash
# Latest Stack (HTTP)
curl -u elastic:$SEARCH_PASSWORD http://localhost:19250/_cluster/health
curl -u admin:$SEARCH_PASSWORD http://localhost:19270/_cluster/health

# Elasticsearch (no TLS)
curl http://localhost:9201/_cluster/health

# Elasticsearch TLS cluster
curl -u elastic:$ELASTIC_PASSWORD https://localhost:9200/_cluster/health

# Elasticsearch production cluster
curl -u elastic:$ELASTIC_PASSWORD https://localhost:9220/_cluster/health
curl -u elastic:$ELASTIC_PASSWORD https://localhost:9220/_cat/nodes?v

# OpenSearch production cluster
curl -k -u admin:$OPENSEARCH_ADMIN_PASSWORD https://localhost:9230/_cluster/health

# MongoDB
docker exec latest-mongo-8-3 mongosh --eval "db.adminCommand('ping')"

# SQLKit Core — PostgreSQL
docker exec sqlkit-postgres-16 pg_isready -U sqlkit

# SQLKit Core — CockroachDB
docker exec sqlkit-cockroachdb-24 ./cockroach sql --insecure -e 'SELECT 1'

# SQLKit PG Ext — OpenGauss
docker exec sqlkit-opengauss pg_isready -U gaussdb
```

## Deploy
deploy OpenSearch service to aws
```bash
./scripts/deploy-opensearch.sh <profile_name> <os_username> <os_password>
```

deploy dynamodb table to aws
```bash
./scripts/deploy-dynamodb.sh <profile_name> <table_name>
```
