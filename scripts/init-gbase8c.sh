#!/usr/bin/env bash
# =============================================================================
# GBase 8c Initialization Script
# =============================================================================
# GBase 8c requires manual initialization after container start:
#   docker exec sqlkit-gbase8c systemctl start etcd.service
#   docker exec sqlkit-gbase8c su - gbase -c "gha_ctl start all -l http://127.0.0.1:2379"
#
# This script automates that process and can be called after:
#   docker compose -f docker-compose-sqlkit-xc.yml up -d
#
# Usage:
#   ./scripts/init-gbase8c.sh                        # start + wait for ready
#   ./scripts/init-gbase8c.sh --oneshot              # start once, no retry
#   ./scripts/init-gbase8c.sh --status               # check if GBase 8c is running
# =============================================================================

set -euo pipefail

CONTAINER="sqlkit-gbase8c"
ETCD_TIMEOUT=30
GBASE_TIMEOUT=120
POLL_INTERVAL=3

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ── Check container status ──────────────────────────────────────────────

check_container() {
  if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    error "Container '${CONTAINER}' is not running."
    echo "  Start it first:"
    echo "    docker compose -f docker-compose-sqlkit-xc.yml up -d"
    return 1
  fi
}

# ── Step 1: Start etcd ──────────────────────────────────────────────────

start_etcd() {
  info "Starting etcd.service..."
  if docker exec "${CONTAINER}" systemctl is-active --quiet etcd.service 2>/dev/null; then
    info "etcd.service already running"
    return 0
  fi

  docker exec "${CONTAINER}" systemctl start etcd.service 2>/dev/null || true

  local elapsed=0
  while [ $elapsed -lt $ETCD_TIMEOUT ]; do
    if docker exec "${CONTAINER}" systemctl is-active --quiet etcd.service 2>/dev/null; then
      info "etcd.service is active"
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done

  error "etcd.service failed to start within ${ETCD_TIMEOUT}s"
  docker exec "${CONTAINER}" systemctl status etcd.service 2>/dev/null || true
  return 1
}

# ── Step 2: Start GBase 8c cluster via gha_ctl ──────────────────────────

start_gbase() {
  info "Starting GBase 8c cluster..."
  if docker exec "${CONTAINER}" su - gbase -c "gha_ctl status all -l http://127.0.0.1:2379" 2>/dev/null | grep -q "running"; then
    info "GBase 8c cluster already running"
    return 0
  fi

  docker exec "${CONTAINER}" su - gbase -c "gha_ctl start all -l http://127.0.0.1:2379" 2>/dev/null || true

  local elapsed=0
  while [ $elapsed -lt $GBASE_TIMEOUT ]; do
    if docker exec "${CONTAINER}" su - gbase -c "gha_ctl status all -l http://127.0.0.1:2379" 2>/dev/null | grep -q "running"; then
      info "GBase 8c cluster is running"
      return 0
    fi
    sleep $POLL_INTERVAL
    elapsed=$((elapsed + POLL_INTERVAL))
  done

  error "GBase 8c cluster failed to start within ${GBASE_TIMEOUT}s"
  docker exec "${CONTAINER}" su - gbase -c "gha_ctl status all -l http://127.0.0.1:2379" 2>/dev/null || true
  return 1
}

# ── Step 3: Verify PG wire is accepting connections ─────────────────────

wait_for_ready() {
  info "Waiting for PostgreSQL wire protocol to accept connections..."
  local elapsed=0
  while [ $elapsed -lt 30 ]; do
    if docker exec "${CONTAINER}" su - gbase -c "gsql -d postgres -c 'SELECT 1'" 2>/dev/null | grep -q "1"; then
      info "GBase 8c is ready! Connect via SQLKit: 10.84.1.213:5437 user=gbase db=postgres"
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done

  warn "pg_isready check timed out, but cluster may still be starting..."
  return 0
}

# ── Status check ────────────────────────────────────────────────────────

show_status() {
  check_container || return 1

  echo ""
  echo "╔════════════════════════════════════════╗"
  echo "║        GBase 8c Status                 ║"
  echo "╠════════════════════════════════════════╣"

  local etcd_ok="no"
  if docker exec "${CONTAINER}" systemctl is-active --quiet etcd.service 2>/dev/null; then
    etcd_ok="yes"
  fi
  printf "║  etcd.service          %6s           ║\n" "$etcd_ok"

  local gbase_ok="no"
  if docker exec "${CONTAINER}" su - gbase -c "gha_ctl status all -l http://127.0.0.1:2379" 2>/dev/null | grep -q "running"; then
    gbase_ok="yes"
  fi
  printf "║  GBase 8c cluster      %6s           ║\n" "$gbase_ok"

  local pg_ok="no"
  if docker exec "${CONTAINER}" su - gbase -c "gsql -d postgres -c 'SELECT 1'" 2>/dev/null | grep -q "1"; then
    pg_ok="yes"
  fi
  printf "║  PG wire connectable   %6s           ║\n" "$pg_ok"

  echo "╚════════════════════════════════════════╝"

  if [ "$etcd_ok" = "yes" ] && [ "$gbase_ok" = "yes" ] && [ "$pg_ok" = "yes" ]; then
    echo ""
    info "GBase 8c is fully operational."
  fi
}

# ── One-time: enable systemd auto-start ──────────────────────────────────

enable_autostart() {
  info "Enabling auto-start for etcd and GBase 8c services..."
  if docker exec "${CONTAINER}" systemctl enable etcd.service 2>/dev/null; then
    info "etcd.service enabled for auto-start"
  else
    warn "Could not enable etcd.service (may already be enabled)"
  fi

  # Create a oneshot systemd service that runs gha_ctl start after etcd
  docker exec "${CONTAINER}" bash -c 'cat > /etc/systemd/system/gbase8c-init.service << '\''EOF'\''
[Unit]
Description=GBase 8c cluster init
Requires=etcd.service
After=etcd.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/su - gbase -c "gha_ctl start all -l http://127.0.0.1:2379"
ExecStop=/bin/su - gbase -c "gha_ctl stop all -l http://127.0.0.1:2379"
User=root

[Install]
WantedBy=multi-user.target
EOF' 2>/dev/null || true

  if docker exec "${CONTAINER}" systemctl enable gbase8c-init.service 2>/dev/null; then
    info "gbase8c-init.service created and enabled for auto-start"
  fi

  echo ""
  info "Auto-start configured. Services will start automatically on container restart."
  echo "  To test: docker restart sqlkit-gbase8c"
  echo ""
}

# ── Main ────────────────────────────────────────────────────────────────

main() {
  case "${1:-}" in
    --status)
      show_status
      exit 0
      ;;
    --oneshot)
      check_container
      start_etcd
      start_gbase
      wait_for_ready
      exit 0
      ;;
    --enable-autostart)
      check_container
      enable_autostart
      exit 0
      ;;
    --help|-h)
      echo "Usage: $0 [OPTION]"
      echo ""
      echo "  (no option)       Full init: start etcd + gbase, wait, verify"
      echo "  --oneshot         Start services once, no retry loop"
      echo "  --status          Show service status"
      echo "  --enable-autostart  One-time: configure systemd auto-start"
      echo "  --help, -h        Show this help"
      exit 0
      ;;
    *)
      check_container
      start_etcd
      start_gbase
      wait_for_ready
      ;;
  esac
}

main "$@"
