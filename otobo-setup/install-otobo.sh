#!/bin/bash
# ==========================================
#  Résolve360 — Installation complète
#  Digital Factory SN
#
#  Ce script orchestre l'installation complète
#  d'une instance Résolve360 pour un client.
#
#  Usage:
#    ./install.sh                   # Mode interactif
#    ./install.sh --non-interactive # Variables via .env
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()      { echo -e "${GREEN}[✓]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[✗]${NC}    $*"; }
log_section() { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}"; }

echo -e "${BOLD}"
echo "╔═══════════════════════════════════════════╗"
echo "║     RÉSOLVE360 — Installation Client      ║"
echo "║     Gestion des Réclamations              ║"
echo "║     Digital Factory SN                    ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"

NON_INTERACTIVE=false
[[ "${1:-}" == "--non-interactive" ]] && NON_INTERACTIVE=true

# ─── Chargement .env ────────────────────────────────────────────
ENV_FILE="${SCRIPT_DIR}/../docker/.env"
if [[ -f "$ENV_FILE" ]]; then
  source "$ENV_FILE"
  log_ok ".env chargé depuis $ENV_FILE"
else
  log_warn "Aucun fichier .env trouvé"
fi

# ─── Mode interactif ────────────────────────────────────────────
if ! $NON_INTERACTIVE; then
  read -rp "$(echo -e "${CYAN}Nom du projet Docker Compose${NC} [otobo-reclam]: ")" INPUT
  COMPOSE_PROJECT="${INPUT:-otobo-reclam}"

  read -rp "$(echo -e "${CYAN}Nom de l'organisation cliente${NC} [Résolve360]: ")" INPUT
  CLIENT_NAME="${INPUT:-Résolve360}"

  read -rp "$(echo -e "${CYAN}FQDN du portail${NC} [reclam.digitalfactory.sn]: ")" INPUT
  CLIENT_FQDN="${INPUT:-reclam.digitalfactory.sn}"

  read -rsp "$(echo -e "${CYAN}Mot de passe root MariaDB${NC}: ")" DB_ROOT_PASS
  echo ""
else
  COMPOSE_PROJECT="${OTOBO_COMPOSE_PROJECT:-otobo-reclam}"
  CLIENT_NAME="${OTOBO_ORGANIZATION:-Résolve360}"
  CLIENT_FQDN="${OTOBO_FQDN:-reclam.digitalfactory.sn}"
  DB_ROOT_PASS="${OTOBO_DB_ROOT_PASSWORD:-}"
fi

if [[ -z "$DB_ROOT_PASS" ]]; then
  log_error "Mot de passe root MariaDB requis"
  exit 1
fi

# ─── Étape 1 : Vérification Docker ──────────────────────────────
log_section "Étape 1/4 : Vérification prérequis"

command -v docker &>/dev/null || { log_error "Docker non installé"; exit 1; }
log_ok "Docker disponible: $(docker --version)"

DB_CONTAINER="${COMPOSE_PROJECT}-db-1"
WEB_CONTAINER="${COMPOSE_PROJECT}-web-1"

docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$" || {
  log_error "Container '${DB_CONTAINER}' introuvable"
  log_info  "Lancez d'abord: docker compose -p ${COMPOSE_PROJECT} up -d"
  exit 1
}
log_ok "Container DB: $DB_CONTAINER"

# ─── Étape 2 : Attendre OTOBO ───────────────────────────────────
log_section "Étape 2/4 : Attente démarrage OTOBO"

MAX_WAIT=120
ELAPSED=0
while ! docker exec "$DB_CONTAINER" mariadb -u root -p"$DB_ROOT_PASS" otobo \
    -e "SELECT 1 FROM ticket LIMIT 1;" &>/dev/null; do
  [[ $ELAPSED -ge $MAX_WAIT ]] && { log_error "Timeout — OTOBO non prêt après ${MAX_WAIT}s"; exit 1; }
  echo -n "."
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done
echo ""
log_ok "Base de données OTOBO prête (${ELAPSED}s)"

# ─── Étape 3 : Appliquer le seed ────────────────────────────────
log_section "Étape 3/4 : Seed Résolve360"

bash "${SCRIPT_DIR}/seed.sh" \
  --project   "$COMPOSE_PROJECT" \
  --db-pass   "$DB_ROOT_PASS" \
  --client    "$CLIENT_NAME" \
  --fqdn      "$CLIENT_FQDN"

# ─── Étape 4 : Vider le cache OTOBO ─────────────────────────────
log_section "Étape 4/4 : Nettoyage cache"

if docker ps --format '{{.Names}}' | grep -q "^${WEB_CONTAINER}$"; then
  docker exec "$WEB_CONTAINER" \
    find /opt/otobo/var/tmp -name "*.cache" -delete 2>/dev/null || true
  log_ok "Cache OTOBO vidé"

  # Rebuild article search index
  docker exec "$WEB_CONTAINER" \
    /opt/otobo/bin/otobo.Console.pl Maint::Ticket::FulltextIndex --rebuild 2>/dev/null | tail -1
  log_ok "Index fulltext reconstruit"
else
  log_warn "Container web non disponible — cache non vidé"
fi

# ─── Résumé final ───────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}"
echo "╔══════════════════════════════════════════════╗"
echo "║   INSTALLATION RÉSOLVE360 TERMINÉE !         ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Client  : ${BOLD}${CLIENT_NAME}${NC}"
echo -e "  Portail : ${CYAN}https://${CLIENT_FQDN}/customer.pl${NC}"
echo -e "  Agents  : ${CYAN}https://${CLIENT_FQDN}/akcil${NC}"
echo -e "  Admin   : ${CYAN}https://${CLIENT_FQDN}/akcil2${NC}"
echo ""
echo -e "  ${YELLOW}Prochaines étapes :${NC}"
echo "  1. Connectez-vous en admin sur /akcil2"
echo "  2. Changez le mot de passe admin (superuser)"
echo "  3. Créez les agents et configurez les files"
echo "  4. Uploadez le logo client dans Admin > SysConfig > Frontend"
echo ""
