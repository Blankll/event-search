# event-search

## ⚠️ Security Notice

**This repository is for LOCAL DEVELOPMENT only.**

All credentials are intentionally simple for ease of use during development:
- Default passwords are provided in `.env.example`
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

Five separate compose files for different database stacks:

| Stack | File | Services |
|-------|------|----------|
| Elasticsearch Versions | `docker-compose.yml` | ES 6/7/8/9 + Kibana, OpenSearch, DynamoDB |
| Elasticsearch TLS Cluster | `elastic-cluster-tls.yml` | 3-node ES cluster + Kibana (TLS enabled) |
| Elasticsearch Production Cluster | `elastic-cluster-production.yml` | 11-node production cluster with dedicated roles |
| OpenSearch Production Cluster | `opensearch-cluster-production.yml` | 11-node + MinIO (Reader/Writer separation) |
| RDS | `docker-compose-rds.yml` | MySQL, PostgreSQL, SQL Server |
| MongoDB | `docker-compose-mongo.yml` | MongoDB 4/5/6/7/8 + Mongo Express |

### Setup

**1. Create environment file:**
```bash
# Copy the example file
cp .env.example .env

# Edit .env and set your passwords (at least 6 characters for each)
# IMPORTANT: Never commit .env to git
```

**2. Required passwords to set:**
- `ELASTIC_PASSWORD` - Elasticsearch admin password
- `KIBANA_PASSWORD` - Kibana system password
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
docker-compose up -d && \
docker-compose -f docker-compose-rds.yml up -d && \
docker-compose -f docker-compose-mongo.yml up -d
```

**Start specific stack:**
```bash
# Elasticsearch versions (no TLS)
docker-compose up -d

# Elasticsearch TLS cluster (3-node with auto certs)
docker-compose -f elastic-cluster-tls.yml up -d

# Elasticsearch production cluster (11-node with dedicated roles)
docker-compose -f elastic-cluster-production.yml up -d

# OpenSearch production cluster (11-node + MinIO for remote store)
docker-compose -f opensearch-cluster-production.yml up -d

# Relational databases
docker-compose -f docker-compose-rds.yml up -d

# MongoDB versions
docker-compose -f docker-compose-mongo.yml up -d
```

**Stop all stacks:**
```bash
docker-compose down && \
docker-compose -f elastic-cluster-tls.yml down && \
docker-compose -f elastic-cluster-production.yml down && \
docker-compose -f opensearch-cluster-production.yml down && \
docker-compose -f docker-compose-rds.yml down && \
docker-compose -f docker-compose-mongo.yml down
```

**Stop specific stack:**
```bash
docker-compose down
docker-compose -f elastic-cluster-tls.yml down
docker-compose -f elastic-cluster-production.yml down
docker-compose -f opensearch-cluster-production.yml down
docker-compose -f docker-compose-rds.yml down
docker-compose -f docker-compose-mongo.yml down
```

**Stop and remove volumes (clean slate):**
```bash
docker-compose down -v && \
docker-compose -f elastic-cluster-tls.yml down -v && \
docker-compose -f elastic-cluster-production.yml down -v && \
docker-compose -f opensearch-cluster-production.yml down -v && \
docker-compose -f docker-compose-rds.yml down -v && \
docker-compose -f docker-compose-mongo.yml down -v
```

### Service Ports Reference

**Elasticsearch Stack (No TLS):**
| Service | Port | UI Port |
|---------|------|---------|
| Elasticsearch 9 | 19200 | Kibana: 5605 |
| Elasticsearch 8 | 9201 | Kibana: 5602 |
| Elasticsearch 7 | 9202 | Kibana: 15601 |
| Elasticsearch 6 | 9203 | Kibana: 5604 |
| OpenSearch 2.8 | 9204 | Dashboards: 5603 |
| DynamoDB Local | 8000 | - |

**Elasticsearch TLS Cluster (3-node):**
| Service | Port | Notes |
|---------|------|-------|
| Elasticsearch (es01) | 9200 (configurable via `.env`) | HTTPS with TLS, user: `elastic` |
| Kibana | 5601 (configurable via `.env`) | Connected to TLS cluster, user: `kibana_system` |

Configuration via `.env` file:
- `STACK_VERSION` - Elasticsearch/Kibana version (default: 8.2.3)
- `ELASTIC_PASSWORD` - Password for `elastic` user
- `KIBANA_PASSWORD` - Password for `kibana_system` user
- `ES_PORT` - Elasticsearch port (default: 9200)
- `KIBANA_PORT` - Kibana port (default: 5601)
- `MEM_LIMIT` - Memory limit per container (default: 1GB)
- `LICENSE` - License type: `basic` or `trial`

**Connect to TLS cluster:**
```bash
# Elasticsearch
curl -u elastic:$ELASTIC_PASSWORD https://localhost:9200

# Kibana UI
open https://localhost:5601
# Login: elastic / $ELASTIC_PASSWORD
```

**Elasticsearch Production Cluster (11-node):**

Production-grade cluster with dedicated node roles for realistic deployment simulation.

| Node Type | Nodes | JVM Heap | Memory Limit | Role |
|-----------|-------|----------|--------------|------|
| Master | 3 | 256MB | 512MB | Cluster state management |
| Data | 5 | 768MB | 1GB | Shard storage & search |
| Coordinating | 2 | 512MB | 768MB | Request routing & aggregation |
| Ingest | 1 | 512MB | 768MB | Pipeline processing |

**Ports:**
| Service | Port | Notes |
|---------|------|-------|
| Coordinating node 1 | 9220 | Load balanced entry point |
| Coordinating node 2 | 9221 | Load balanced entry point |
| Kibana | 5620 | Web UI |

**Architecture:**
```
Client → Coordinating (9220/9221) → Data nodes (5) ← Master nodes (3)
                                    ↑
                              Ingest node (1)
```

**Recommended index settings:**
```json
{
  "number_of_shards": 5,
  "number_of_replicas": 1
}
```

**Connect to production cluster:**
```bash
# Through coordinating node (recommended for clients)
curl -u elastic:$ELASTIC_PASSWORD https://localhost:9220/_cluster/health

# View node roles
curl -u elastic:$ELASTIC_PASSWORD https://localhost:9220/_cat/nodes?v

# Kibana UI
open https://localhost:5620
# Login: elastic / $ELASTIC_PASSWORD
```

**Memory footprint:** ~7GB total (fits 12GB machine with 5GB buffer)

Configuration via `.env` file:
- `CLUSTER_NAME_PROD` - Production cluster name
- `ES_PORT_PROD_1` / `ES_PORT_PROD_2` - Coordinating node ports
- `KIBANA_PORT_PROD` - Production Kibana port

**OpenSearch Production Cluster (11-node + MinIO):**

Production-grade OpenSearch 3.6 cluster with Reader/Writer separation architecture.

| Node Type | Nodes | JVM Heap | Memory Limit | Role |
|-----------|-------|----------|--------------|------|
| Cluster Manager | 3 | 256MB | 512MB | Cluster state management |
| Data (Indexing Fleet) | 3 | 768MB | 1GB | Primary shards + write replicas |
| Search (Search Fleet) | 2 | 512MB | 768MB | Search replicas (query only) |
| Coordinating | 2 | 512MB | 768MB | Request routing |
| Dashboards | 1 | 512MB | 768MB | Web UI |
| MinIO | 1 | - | 512MB | Remote store (S3-compatible) |

**Ports:**
| Service | Port | Notes |
|---------|------|-------|
| Coordinating node 1 | 9230 | Load balanced entry point |
| Coordinating node 2 | 9231 | Load balanced entry point |
| Dashboards | 5630 | Web UI |
| MinIO API | 9000 | S3-compatible storage |
| MinIO Console | 9001 | Web UI (credentials from `.env`) |

**Architecture (Reader/Writer Separation):**
```
Client → Coordinating (9230/9231)
           │
           ├─ Indexing → Data nodes (3) → MinIO (segments/translog)
           │              [Primaries + Write Replicas]
           │
           └─ Search → Search nodes (2) ← MinIO (segment download)
                        [Search Replicas]
           │
Cluster Manager nodes (3) ← All nodes
```

**Key OpenSearch 3.x Features:**
- **Search Node Role** - Dedicated query-serving nodes
- **Remote-backed Storage** - MinIO as S3-compatible segment store
- **Segment Replication** - Replicas download from remote store
- **Reader/Writer Separation** - Independent scaling of indexing/search
- **Lucene 10** - 10x search performance improvement
- **Concurrent Segment Search** - Auto-enabled parallel queries

**Recommended index settings (for search replicas):**
```json
{
  "number_of_shards": 3,
  "number_of_replicas": 1,
  "number_of_search_replicas": 2,
  "index.replication.type": "SEGMENT"
}
```

**Connect to OpenSearch cluster:**
```bash
# Through coordinating node (with auth)
curl -k -u admin:$OPENSEARCH_ADMIN_PASSWORD https://localhost:9230/_cluster/health

# View node roles (search role visible)
curl -k -u admin:$OPENSEARCH_ADMIN_PASSWORD https://localhost:9230/_cat/nodes?v

# View search replicas
curl -k -u admin:$OPENSEARCH_ADMIN_PASSWORD https://localhost:9230/_cat/shards?v

# Dashboards UI (with login)
open http://localhost:5630
# Login: admin / $OPENSEARCH_ADMIN_PASSWORD (from .env)
```

**MinIO Console:**
```bash
open http://localhost:9001
# Login: opensearch / $MINIO_ROOT_PASSWORD (from .env)
# Buckets: opensearch-segments, opensearch-translog, opensearch-state
```

**Security Credentials:**
- **OpenSearch API**: user: `admin`, pass: `${OPENSEARCH_ADMIN_PASSWORD}` (from `.env`)
- **OpenSearch Dashboards**: user: `admin`, pass: `${OPENSEARCH_ADMIN_PASSWORD}` (from `.env`)
- **MinIO Console**: user: `${MINIO_ROOT_USER}`, pass: `${MINIO_ROOT_PASSWORD}` (from `.env`)

Configuration via `.env` file:
- `OPENSEARCH_CLUSTER_NAME_PROD` - OpenSearch cluster name
- `OPENSEARCH_PORT_PROD_1` / `OPENSEARCH_PORT_PROD_2` - Coordinating node ports
- `OPENSEARCH_DASHBOARDS_PORT_PROD` - Dashboards port
- `OPENSEARCH_ADMIN_PASSWORD` - Admin user password (HTTPS auth)
- `OPENSEARCH_KIBANA_PASSWORD` - Dashboards server password (internal)

**RDS Stack:**
| Service | Port | Credentials |
|---------|------|-------------|
| MySQL 5.7 | 3306 | user: `eventuser-mysql`, pass: `${MYSQL_PASSWORD}`, db: `eventdb-mysql` |
| PostgreSQL 16 | 5432 | user: `eventuser-postgres`, pass: `${POSTGRES_PASSWORD}`, db: `eventdb-postgres` |
| SQL Server 2022 | 1433 | user: `sa`, pass: `${SA_PASSWORD}`, db: `master` |

**MongoDB Stack:**
| Version | Port | Mongo Express | Key Feature |
|---------|------|---------------|-------------|
| 4.4 | 27017 | 8081 | Last stable before wire protocol changes |
| 5.0 | 27018 | 8082 | Time series collections |
| 6.0 | 27019 | 8083 | Change streams enhancement |
| 7.0 | 27020 | 8084 | Queryable encryption |
| 8.0 | 27021 | 8085 | Latest (2024) performance updates |

Mongo Express credentials: `admin` / `${MONGO_EXPRESS_PASSWORD}` (from `.env`)

### Useful Commands

**View running containers:**
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**View logs:**
```bash
docker logs event-mongo-6
docker logs -f event-es-8  # follow mode
```

**Check container health:**
```bash
# Elasticsearch (no TLS)
curl http://localhost:9201/_cluster/health

# Elasticsearch TLS cluster
curl -u elastic:$ELASTIC_PASSWORD https://localhost:9200/_cluster/health

# Elasticsearch production cluster
curl -u elastic:$ELASTIC_PASSWORD https://localhost:9220/_cluster/health
curl -u elastic:$ELASTIC_PASSWORD https://localhost:9220/_cat/nodes?v  # View node roles
curl -u elastic:$ELASTIC_PASSWORD https://localhost:9220/_cat/shards?v  # View shard distribution

# OpenSearch production cluster
curl -k -u admin:$OPENSEARCH_ADMIN_PASSWORD https://localhost:9230/_cluster/health
curl -k -u admin:$OPENSEARCH_ADMIN_PASSWORD https://localhost:9230/_cat/nodes?v  # View node roles (cluster_manager, data, search)
curl -k -u admin:$OPENSEARCH_ADMIN_PASSWORD https://localhost:9230/_cat/shards?v  # View search replicas

# MongoDB
docker exec event-mongo-6 mongosh --eval "db.runCommand({ ping: 1 })"

# PostgreSQL
docker exec postgres pg_isready
```

**TLS cluster certificate location:**
Certificates are auto-generated and stored in Docker volume `certs`. To extract:
```bash
docker run --rm -v certs:/certs -v $(pwd):/out alpine cp -r /certs /out
```

## deploy
deploy OpenSearch service to aws
```bash
./scripts/deploy-opensearch.sh <profile_name> <os_username> <os_password>
```

deploy dynamodb table to aws
```bash
./scripts/deploy-dynamodb.sh <profile_name> <table_name>
```
