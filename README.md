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

Seven separate compose files for different database stacks:

| Stack | File | Services | Memory (Approx) |
|-------|------|----------|-----------------|
| **Version Mix** | `docker-compose.yml` | ES 6/7/8/9 + Kibana, OpenSearch, Easysearch, DynamoDB | ~6 GB |
| **Latest Stack** 🔥 | `docker-compose-latest.yml` | ES 9.4, ES 7.17, OS 3.5, Easysearch, DynamoDB, Mongo 4.0/8.3 | ~3.7 GB |
| **ES TLS Cluster** | `elastic-cluster-tls.yml` | 3-node ES cluster + Kibana (TLS enabled) | ~3 GB |
| **ES Production Cluster** | `elastic-cluster-production.yml` | 11-node ES 9.4 cluster with dedicated roles | ~13 GB |
| **OS Production Cluster** | `opensearch-cluster-production.yml` | 11-node OS + MinIO (Reader/Writer separation) | ~10 GB |
| **RDS** | `docker-compose-rds.yml` | MySQL, PostgreSQL, SQL Server | ~2 GB |
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
- `MYSQL_ROOT_PASSWORD` - MySQL root password
- `MYSQL_PASSWORD` - MySQL application password
- `POSTGRES_PASSWORD` - PostgreSQL password
- `SA_PASSWORD` - SQL Server SA password
- `MONGO_EXPRESS_PASSWORD` - Mongo Express web UI password

### Start/Stop Commands

**Start all stacks (parallel):**
```bash
docker compose up -d && \
docker compose -f docker-compose-latest.yml up -d && \
docker compose -f elastic-cluster-tls.yml up -d && \
docker compose -f elastic-cluster-production.yml up -d && \
docker compose -f opensearch-cluster-production.yml up -d && \
docker compose -f docker-compose-rds.yml up -d && \
docker compose -f docker-compose-mongo.yml up -d
```

**Stop all stacks:**
```bash
docker compose down && \
docker compose -f docker-compose-latest.yml down && \
docker compose -f elastic-cluster-tls.yml down && \
docker compose -f elastic-cluster-production.yml down && \
docker compose -f opensearch-cluster-production.yml down && \
docker compose -f docker-compose-rds.yml down && \
docker compose -f docker-compose-mongo.yml down
```

**Stop and remove volumes (clean slate):**
```bash
docker compose down -v && \
docker compose -f docker-compose-latest.yml down -v && \
docker compose -f elastic-cluster-tls.yml down -v && \
docker compose -f elastic-cluster-production.yml down -v && \
docker compose -f opensearch-cluster-production.yml down -v && \
docker compose -f docker-compose-rds.yml down -v && \
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

### RDS Stack (`docker-compose-rds.yml`)
| Service | Port | Credentials |
|---------|------|-------------|
| MySQL 5.7 | 3306 | user: `eventuser-mysql`, pass: `$MYSQL_PASSWORD`, db: `eventdb-mysql` |
| PostgreSQL 16 | 5432 | user: `eventuser-postgres`, pass: `$POSTGRES_PASSWORD`, db: `eventdb-postgres` |
| SQL Server 2022 | 1433 | user: `sa`, pass: `$SA_PASSWORD`, db: `master` |

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

# PostgreSQL
docker exec postgres pg_isready
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
