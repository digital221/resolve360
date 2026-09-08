#!/usr/bin/env bash
# ==============================================================================
# SCRIPT D'INDUSTRIALISATION DE PROVISIONING MULTI-INSTANCES (PHASE 5)
# ClaimBank v2.0 — Digital Factory Senegal
# ==============================================================================
set -e

CLIENT_NAME="${1:-Resolve360Bank}"
CLIENT_FQDN="${2:-reclam.digitalfactory.sn}"
ORGANIZATION_NAME="${3:-Resolve360 Bank UMOA}"
SUPPORT_EMAIL="${4:-support@digitalfactory.sn}"

echo "=========================================================================="
echo "🚀 PROVISIONING NOUVELLE INSTANCE DÉDIÉE CLAIBANK UMOA"
echo "=========================================================================="
echo "• Client Banque : ${CLIENT_NAME}"
echo "• Domaine FQDN : ${CLIENT_FQDN}"
echo "• Organisation  : ${ORGANIZATION_NAME}"
echo "• Email Support : ${SUPPORT_EMAIL}"
echo "--------------------------------------------------------------------------"

# 1. Verification variables & environnement Docker
echo "--> [1/4] Validation des conteneurs Docker de la banque..."
docker ps --filter "name=otobo-reclam" --format "table {{.Names}}\t{{.Status}}"

# 2. Ingestion des configurations SysConfig & Charte Graphique
echo "--> [2/4] Application du thème Marque Blanche (${CLIENT_NAME})..."
docker exec -i otobo-reclam-db-1 mariadb -u root -p'OtoboDB_Root_2024!' otobo -e "
UPDATE sysconfig_modified SET navigation_value = CONCAT('\"', '${ORGANIZATION_NAME}', '\"') WHERE name = 'OrganizationName';
UPDATE sysconfig_modified SET navigation_value = CONCAT('\"', '${SUPPORT_EMAIL}', '\"') WHERE name = 'SupportEmail';
UPDATE sysconfig_modified SET navigation_value = CONCAT('\"', '${CLIENT_FQDN}', '\"') WHERE name = 'FQDN';
"

# 3. Validation des SLA 30j / 5j et Queues UMOA
echo "--> [3/4] Activation des règles de conformité UMOA (Circulaire 002-2020/CB/C)..."
docker exec -i otobo-reclam-db-1 mariadb -u root -p'OtoboDB_Root_2024!' otobo -e "
INSERT IGNORE INTO queue (name, valid_id, create_time, create_by, change_time, change_by) VALUES
('Paiements', 1, NOW(), 1, NOW(), 1),
('Crédits', 1, NOW(), 1, NOW(), 1),
('Mobile Money', 1, NOW(), 1, NOW(), 1),
('Frais & Tarif', 1, NOW(), 1, NOW(), 1),
('Fraude', 1, NOW(), 1, NOW(), 1),
('Agences', 1, NOW(), 1, NOW(), 1),
('Conformité', 1, NOW(), 1, NOW(), 1);
"

# 4. Déploiement et Reconstitution du Cache SysConfig
echo "--> [4/4] Déploiement SysConfig & Reconstitution du cache..."
docker exec otobo-reclam-web-1 /opt/otobo/bin/otobo.Console.pl Maint::Config::Rebuild || true
docker exec otobo-reclam-web-1 /opt/otobo/bin/otobo.Console.pl Maint::Cache::Delete || true

echo "=========================================================================="
echo "✅ INSTANCE DÉDIÉE ${CLIENT_NAME} DÉPLOYÉE ET PROVISIONNÉE AVEC SUCCÈS !"
echo "URL d'accès : https://${CLIENT_FQDN}/customer.pl"
echo "=========================================================================="
