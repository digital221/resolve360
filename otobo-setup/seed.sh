#!/bin/bash
# ==========================================
#  Résolve360 — Seed de déploiement
#  Digital Factory SN
#
#  Usage: ./seed.sh [options]
#    --project   Nom du projet Docker Compose (défaut: otobo-reclam)
#    --db-pass   Mot de passe root MariaDB
#    --client    Nom de l'organisation cliente
#    --fqdn      Nom de domaine (ex: reclam.banque.sn)
#    --dry-run   Afficher les opérations sans les exécuter
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Couleurs ───────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()      { echo -e "${GREEN}[✓]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[✗]${NC}    $*"; }
log_section() { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}"; }

# ─── Paramètres ─────────────────────────────────────────────────
COMPOSE_PROJECT="${RESOLVE360_PROJECT:-otobo-reclam}"
DB_ROOT_PASS="${RESOLVE360_DB_ROOT_PASS:-}"
CLIENT_NAME="${RESOLVE360_CLIENT:-Résolve360}"
CLIENT_FQDN="${RESOLVE360_FQDN:-reclam.digitalfactory.sn}"
DRY_RUN=false

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --project)   COMPOSE_PROJECT="$2"; shift 2 ;;
    --db-pass)   DB_ROOT_PASS="$2"; shift 2 ;;
    --client)    CLIENT_NAME="$2"; shift 2 ;;
    --fqdn)      CLIENT_FQDN="$2"; shift 2 ;;
    --dry-run)   DRY_RUN=true; shift ;;
    *) log_error "Option inconnue: $1"; exit 1 ;;
  esac
done

# Charger .env si disponible
ENV_FILE="${SCRIPT_DIR}/../docker/.env"
if [[ -f "$ENV_FILE" ]]; then
  source "$ENV_FILE"
  DB_ROOT_PASS="${DB_ROOT_PASS:-$OTOBO_DB_ROOT_PASSWORD}"
  CLIENT_NAME="${CLIENT_NAME:-${OTOBO_ORGANIZATION:-Résolve360}}"
  CLIENT_FQDN="${CLIENT_FQDN:-${OTOBO_FQDN:-reclam.digitalfactory.sn}}"
fi

if [[ -z "$DB_ROOT_PASS" ]]; then
  log_error "Mot de passe root MariaDB manquant."
  echo "  Définissez RESOLVE360_DB_ROOT_PASS ou passez --db-pass <password>"
  exit 1
fi

# ─── Identification des containers ──────────────────────────────
DB_CONTAINER="${COMPOSE_PROJECT}-db-1"
WEB_CONTAINER="${COMPOSE_PROJECT}-web-1"

echo -e "\n${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   RÉSOLVE360 — Seed de déploiement      ║${NC}"
echo -e "${BOLD}║   Digital Factory SN                     ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
log_info "Projet Docker : ${COMPOSE_PROJECT}"
log_info "Client        : ${CLIENT_NAME}"
log_info "FQDN          : ${CLIENT_FQDN}"
log_info "DB container  : ${DB_CONTAINER}"
$DRY_RUN && log_warn "Mode DRY-RUN activé — aucune modification ne sera appliquée"
echo ""

# ─── Helpers ────────────────────────────────────────────────────
run_sql() {
  local sql="$1"
  if $DRY_RUN; then
    echo -e "  ${YELLOW}[DRY-RUN SQL]${NC} ${sql:0:80}..."
    return 0
  fi
  echo "SET NAMES utf8mb4; $sql" | docker exec -i "$DB_CONTAINER" mariadb \
    --default-character-set=utf8mb4 \
    -u root -p"$DB_ROOT_PASS" otobo 2>/dev/null || true
}

run_sql_file() {
  local file="$1"
  if $DRY_RUN; then
    log_warn "[DRY-RUN] Exécution de: $file"
    return 0
  fi
  docker cp "$file" "${DB_CONTAINER}:/tmp/seed_$(basename "$file")"
  docker exec "$DB_CONTAINER" mariadb \
    --default-character-set=utf8mb4 \
    -u root -p"$DB_ROOT_PASS" otobo \
    < "/tmp/seed_$(basename "$file")" 2>/dev/null
}

check_container() {
  docker ps --format '{{.Names}}' | grep -q "^$1$"
}

# ─── Vérifications préalables ────────────────────────────────────
log_section "Vérifications"

check_container "$DB_CONTAINER" || {
  log_error "Container DB '$DB_CONTAINER' introuvable ou arrêté."
  log_info  "Démarrez d'abord OTOBO avec: docker compose -p $COMPOSE_PROJECT up -d"
  exit 1
}
log_ok "Container DB trouvé: $DB_CONTAINER"

check_container "$WEB_CONTAINER" || log_warn "Container Web '$WEB_CONTAINER' non trouvé (OK pour seed DB only)"

# ─── 1. Branding — ProductName & SysConfig ──────────────────────
log_section "1/6 Branding SysConfig"

run_sql "
UPDATE system_data
SET data_value = '${CLIENT_NAME}'
WHERE data_key = 'ProductName';

INSERT INTO system_data (data_key, data_value, create_time, create_by, change_time, change_by)
VALUES ('ProductName', '${CLIENT_NAME}', NOW(), 1, NOW(), 1)
ON DUPLICATE KEY UPDATE data_value = '${CLIENT_NAME}', change_time = NOW();
"
log_ok "ProductName → ${CLIENT_NAME}"

# ─── 2. Ticket de bienvenue ──────────────────────────────────────
log_section "2/6 Ticket de bienvenue"

run_sql "
UPDATE ticket SET title = 'Bienvenue sur ${CLIENT_NAME} !' WHERE id = 1;
"
log_ok "Titre ticket → 'Bienvenue sur ${CLIENT_NAME} !'"

run_sql "
UPDATE article SET a_subject = 'Bienvenue sur ${CLIENT_NAME} !' WHERE ticket_id = 1;
"
log_ok "Sujet article mis à jour"

run_sql "
UPDATE article_data_mime SET
  a_from      = 'Digital Factory SN | Équipe ${CLIENT_NAME} <support@digitalfactory.sn>',
  a_to        = 'Administrateur ${CLIENT_NAME} <admin@${CLIENT_FQDN}>',
  a_subject   = 'Bienvenue sur ${CLIENT_NAME} !',
  a_body      = 'Bienvenue sur ${CLIENT_NAME} !

Merci d utiliser ${CLIENT_NAME}, la solution de gestion des réclamations
et du service client développée par Digital Factory SN.

${CLIENT_NAME} est conçu pour les institutions financières, banques,
assurances et organismes de service client.


CONTACT ET SUPPORT
Email   : support@digitalfactory.sn
Site    : https://www.digitalfactory.sn
Portail : https://${CLIENT_FQDN}


PRISE EN MAIN RAPIDE
1. Créez vos agents         : Admin > Gestion des utilisateurs > Agents
2. Configurez vos files     : Admin > Gestion des tickets > Files
3. Personnalisez les groupes: Admin > Gestion des utilisateurs > Groupes
4. Activez les notifications: Admin > Gestion des tickets > Notifications
5. Ajoutez vos clients      : Admin > Gestion des utilisateurs > Clients


Bonne utilisation de ${CLIENT_NAME} !
L equipe Digital Factory SN
https://www.digitalfactory.sn',
  change_time = NOW(),
  change_by   = 1
WHERE article_id = 1;
"
log_ok "Corps du ticket welcome mis à jour"

# Mettre à jour la table article_data_mime_plain également
run_sql "
UPDATE article_data_mime_plain SET
  body        = 'Bienvenue sur ${CLIENT_NAME} !

Merci d utiliser ${CLIENT_NAME}, la solution de gestion des réclamations
et du service client développée par Digital Factory SN.',
  change_time = NOW(),
  change_by   = 1
WHERE article_id = 1;
"
log_ok "article_data_mime_plain mis à jour"

# ─── 3. Supprimer les notifications email OTOBO/Rother & injecter Politique de Confidentialité ──────────
log_section "3/6 Nettoyage OTOBO & Politique de Confidentialité"

run_sql "
DELETE FROM system_data
WHERE data_key IN (
  'OTOBONews', 'SubscribedProducts', 'Daemon::SchedulerCronTaskManager::Task::OTOBOBusinessEntitlementCheck'
);
"
log_ok "Entrées news/subscription OTOBO supprimées"

run_sql "
DELETE FROM data_storage WHERE ds_type = 'CustomerAccept';
INSERT INTO data_storage (ds_type, ds_key, ds_value, create_time, create_by)
VALUES 
('CustomerAccept', 'fr', '{\"ContentType\":\"text/html\",\"Body\":\"<h1>Politique de Confidentialité — ${CLIENT_NAME}</h1><p>La protection de vos données personnelles et la confidentialité des informations traitées sur <strong>${CLIENT_NAME}</strong> constituent un engagement prioritaire pour <strong>Digital Factory SN</strong>.</p>&nbsp;<h2>1. Champ d\'application</h2><p>La présente Politique de Confidentialité s\'applique à l\'utilisation de la plate-forme de gestion des réclamations et du service client <strong>${CLIENT_NAME}</strong>.</p>&nbsp;<h2>2. Collecte et traitement des données</h2><p>Dans le cadre de la gestion et du suivi de vos réclamations, les données suivantes sont collectées et traitées :</p><ul><li><strong>Identité & Coordonnées :</strong> Prénom, nom, adresse e-mail, téléphone, identifiant usager.</li><li><strong>Réclamations & Correspondances :</strong> Objet, détails du dossier, pièces justificatives et échanges avec les agents.</li></ul><p>Ces informations sont exclusivement utilisées pour l\'instruction et la résolution de vos réclamations conformément à la réglementation en vigueur.</p>&nbsp;<h2>3. Protection & Sécurité</h2><p>Toutes les données sont chiffrées en transit et stockées au sein d\'infrastructures sécurisées. L\'accès aux dossiers est strictement réservé aux agents habilités.</p>&nbsp;<h2>4. Vos droits</h2><p>Vous disposez d\'un droit d\'accès, de rectification et de suivi de vos données en contactant notre équipe support à <a href=\\\"mailto:support@digitalfactory.sn\\\">support@digitalfactory.sn</a>.</p>\"}', NOW(), 1),
('CustomerAccept', 'en', '{\"ContentType\":\"text/html\",\"Body\":\"<h1>Politique de Confidentialité — ${CLIENT_NAME}</h1><p>La protection de vos données personnelles et la confidentialité des informations traitées sur <strong>${CLIENT_NAME}</strong> constituent un engagement prioritaire pour <strong>Digital Factory SN</strong>.</p>&nbsp;<h2>1. Champ d\'application</h2><p>La présente Politique de Confidentialité s\'applique à l\'utilisation de la plate-forme de gestion des réclamations et du service client <strong>${CLIENT_NAME}</strong>.</p>&nbsp;<h2>2. Collecte et traitement des données</h2><p>Dans le cadre de la gestion et du suivi de vos réclamations, les données suivantes sont collectées et traitées :</p><ul><li><strong>Identité & Coordonnées :</strong> Prénom, nom, adresse e-mail, téléphone, identifiant usager.</li><li><strong>Réclamations & Correspondances :</strong> Objet, détails du dossier, pièces justificatives et échanges avec les agents.</li></ul><p>Ces informations sont exclusivement utilisées pour l\'instruction et la résolution de vos réclamations conformément à la réglementation en vigueur.</p>&nbsp;<h2>3. Protection & Sécurité</h2><p>Toutes les données sont chiffrées en transit et stockées au sein d\'infrastructures sécurisées. L\'accès aux dossiers est strictement réservé aux agents habilités.</p>&nbsp;<h2>4. Vos droits</h2><p>Vous disposez d\'un droit d\'accès, de rectification et de suivi de vos données en contactant notre équipe support à <a href=\\\"mailto:support@digitalfactory.sn\\\">support@digitalfactory.sn</a>.</p>\"}', NOW(), 1);
"
log_ok "Politique de Confidentialité Résolve360 injectée en base de données"

# ─── 4. Configuration SysConfig — Branding ───────────────────────
log_section "4/6 SysConfig branding étendu"

SYSCONFIGS=(
  "ProductName:::${CLIENT_NAME}"
  "Organization:::Digital Factory SN"
  "AdminEmail:::support@digitalfactory.sn"
)

for entry in "${SYSCONFIGS[@]}"; do
  KEY="${entry%%:::*}"
  VAL="${entry##*:::}"
  run_sql "
  INSERT INTO system_data (data_key, data_value, create_time, create_by, change_time, change_by)
  VALUES ('${KEY}', '${VAL}', NOW(), 1, NOW(), 1)
  ON DUPLICATE KEY UPDATE data_value = '${VAL}', change_time = NOW();
  "
  log_ok "SysConfig: $KEY → $VAL"
done

# Correctif sysconfig_default pour Secure::DisableBanner (YAML valide '--- \'1\'\n')
run_sql "
UPDATE sysconfig_default SET effective_value = '--- \'1\'\n' WHERE name = 'Secure::DisableBanner';
UPDATE sysconfig_default_version SET effective_value = '--- \'1\'\n' WHERE name = 'Secure::DisableBanner';
"
log_ok "Secure::DisableBanner → YAML 1"

# ─── 5. File de seed — Config kernel ─────────────────────────────
log_section "5/6 Fichier kernel ZZZAResolve360"

KERNEL_CONFIG_FILE="${SCRIPT_DIR}/configs/ZZZAResolve360.pm"
if [[ -f "$KERNEL_CONFIG_FILE" ]]; then
  if ! $DRY_RUN; then
    docker exec "$WEB_CONTAINER" mkdir -p /opt/otobo/Kernel/Config/Files/User 2>/dev/null || true
    if docker cp "$KERNEL_CONFIG_FILE" "${WEB_CONTAINER}:/opt/otobo/Kernel/Config/Files/User/ZZZAResolve360.pm" 2>/dev/null; then
      docker exec "$WEB_CONTAINER" chown -R otobo:otobo /opt/otobo/Kernel/Config/Files/User 2>/dev/null || true
      log_ok "Config kernel copiée dans Kernel/Config/Files/User/"
    else
      log_warn "Impossible de copier la config kernel"
    fi
  else
    log_warn "[DRY-RUN] Copie config kernel: $KERNEL_CONFIG_FILE"
  fi
else
  log_warn "Fichier $KERNEL_CONFIG_FILE introuvable — ignoré"
fi

# Correctif syntaxe fr.pm et traductions Résolve360
if ! $DRY_RUN; then
  docker exec "$WEB_CONTAINER" perl -pi -e 's/^\s*'\''Request Account'\'' => '\''Créer un compte'\'',//g' /opt/otobo/Kernel/Language/fr.pm 2>/dev/null
  docker exec "$WEB_CONTAINER" perl -pi -e 's/# \$\$STOP\$\$/    '\''Request Account'\'' => '\''Créer un compte'\'',\n    # \$\$STOP\$\$/g' /opt/otobo/Kernel/Language/fr.pm 2>/dev/null
  docker exec "$WEB_CONTAINER" perl -pi -e 's/'\''Ticket Search'\'' => '\'\''/'\''Ticket Search'\'' => '\''Recherche réclamation'\''/g' /opt/otobo/Kernel/Language/fr.pm 2>/dev/null
  docker exec "$WEB_CONTAINER" perl -pi -e 's/# \$\$STOP\$\$/    '\''Create a ticket'\'' => '\''Créer une réclamation'\'',\n    '\''Create ticket'\'' => '\''Créer une réclamation'\'',\n    '\''Your last tickets'\'' => '\''Vos dernières réclamations'\'',\n    # \$\$STOP\$\$/g' /opt/otobo/Kernel/Language/fr.pm 2>/dev/null
  docker exec "$WEB_CONTAINER" perl -pi -e 's/Il y a %s erreur de réseau possibles./%s a détecté un problème de réseau./g' /opt/otobo/Kernel/Language/fr.pm 2>/dev/null
  
  # Génération du module de traduction personnalisé fr_Custom.pm
  docker exec -i "$WEB_CONTAINER" bash -c 'cat << "EOF" > /opt/otobo/Kernel/Language/fr_Custom.pm
package Kernel::Language::fr_Custom;

use strict;
use warnings;

sub Data {
    my $Self = shift;
    my $Lang = $Self->{Translation};

    # Overrides and custom French translations for Resolve360
    $Lang->{"Ticket Search"}               = "Recherche réclamation";
    $Lang->{"Ticket Search."}              = "Recherche réclamation";
    $Lang->{"Create%sa ticket"}             = "Créer%sune réclamation";
    $Lang->{"Create a ticket"}              = "Créer une réclamation";
    $Lang->{"Your last tickets"}            = "Vos dernières réclamations";
    $Lang->{"Welcome %s, to your OTOBO."}   = "Bienvenue %s sur votre espace Résolve360.";
    $Lang->{"This service portal is available to you all day every day."} = "Votre portail de gestion des réclamations est accessible 24h/24 et 7j/7.";
    $Lang->{"Explore >"}                    = "Découvrir Digital Factory SN >";
    $Lang->{"Message of the day"}           = "Message du jour";
    $Lang->{"Your external tools"}          = "Vos outils externes";
    $Lang->{"Overview"}                     = "Aperçu";
    $Lang->{"Network error"}                = "Erreur réseau. Veuillez réessayer.";
    $Lang->{"OTOBO 11.1 | Service Management"} = "Résolve360 | Service Client";
    $Lang->{"Your Tickets. Your OTOBO."}   = "Vos Réclamations. Votre Espace Résolve360.";
    $Lang->{"OTOBO News"}                   = "Nouveautés Résolve360";
    $Lang->{"News about OTOBO."}            = "Nouveautés à propos de Résolve360.";
    $Lang->{"Jump to OTOBO!"}              = "Accéder à Résolve360 !";

    return 1;
}

1;
EOF
chown otobo:otobo /opt/otobo/Kernel/Language/fr_Custom.pm
' 2>/dev/null || true
  log_ok "Fichier langue fr_Custom.pm généré"
fi

# Nettoyage des tuiles d'exemples dans xml_storage
run_sql "DELETE FROM xml_storage WHERE xml_type = 'InfoTiles';"
log_ok "Tuiles d'exemple XML supprimées"

# Reconstruire la config OTOBO
if ! $DRY_RUN; then
  docker exec "$WEB_CONTAINER" /opt/otobo/bin/otobo.Console.pl Maint::Config::Rebuild 2>/dev/null && \
    docker exec "$WEB_CONTAINER" /opt/otobo/bin/otobo.Console.pl Maint::Cache::Delete 2>/dev/null && \
    log_ok "Cache et configuration OTOBO reconstruits avec succès"
fi


# ─── 6. Templates HTML ───────────────────────────────────────────
log_section "6/6 Templates HTML branding"

TEMPLATES_DIR="${SCRIPT_DIR}/templates"
if [[ -d "$TEMPLATES_DIR" ]] && ! $DRY_RUN; then
  for tpl in "$TEMPLATES_DIR"/*.tt; do
    [[ -f "$tpl" ]] || continue
    DEST_FILE="/opt/otobo/Kernel/Output/HTML/Templates/Standard/$(basename "$tpl")"
    docker cp "$tpl" "${WEB_CONTAINER}:${DEST_FILE}" 2>/dev/null && \
      log_ok "Template copié: $(basename "$tpl")" || \
      log_warn "Impossible de copier $(basename "$tpl")"
  done
else
  log_warn "Dossier templates non trouvé ou dry-run — ignoré"
fi

# ─── Résumé ──────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}══════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  SEED TERMINÉ AVEC SUCCÈS !              ${NC}"
echo -e "${BOLD}${GREEN}══════════════════════════════════════════${NC}"
echo ""
echo -e "  🌐 Portail client : ${CYAN}https://${CLIENT_FQDN}/customer.pl${NC}"
echo -e "  🔑 Interface agent: ${CYAN}https://${CLIENT_FQDN}/akcil${NC}"
echo -e "  ⚙️  Admin          : ${CYAN}https://${CLIENT_FQDN}/akcil2${NC}"
echo ""
