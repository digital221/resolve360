#!/bin/bash
# ==========================================
# Résolve360 — Script d'installation OTOBO
# Digital Factory SN
# ==========================================

set -e

echo "
╔═══════════════════════════════════════╗
║       RÉSOLVE360 — INSTALLATION       ║
║   Gestion des Réclamations Bancaires  ║
╚═══════════════════════════════════════╝
"

# Variables
VPS_IP="209.126.11.165"
OTOBO_PORT=8420
INSTALL_DIR="/opt/otobo-reclam"
COMPOSE_PROJECT="otobo-reclam"

# Vérifications
command -v docker &>/dev/null || { echo "❌ Docker non installé"; exit 1; }
command -v docker compose &>/dev/null || { echo "❌ Docker Compose non installé"; exit 1; }

echo "✅ Prérequis OK"

# Créer le répertoire
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Copier les fichiers docker
cp "$(dirname "$0")/docker-compose.yml" . 2>/dev/null || \
  curl -sL https://raw.githubusercontent.com/RotherOSS/otobo-docker/main/otobo-base.yml -o docker-compose.yml

# Charger les variables
if [ -f ".env" ]; then
  source .env
else
  echo "⚠️  Fichier .env manquant. Copiez docker/.env.example vers $INSTALL_DIR/.env et configurez-le."
  exit 1
fi

echo "🚀 Démarrage des conteneurs OTOBO..."
docker compose -p "$COMPOSE_PROJECT" up -d

echo ""
echo "⏳ Attente que les services soient prêts..."
sleep 15

echo ""
echo "📊 Statut des conteneurs :"
docker compose -p "$COMPOSE_PROJECT" ps

echo ""
echo "✅ Installation terminée !"
echo ""
echo "🌐 Accès :"
echo "   Installer : http://$VPS_IP:$OTOBO_PORT/otobo/installer.pl"
echo "   Agent     : http://$VPS_IP:$OTOBO_PORT/otobo/index.pl"
echo "   Client    : http://$VPS_IP:$OTOBO_PORT/otobo/customer.pl"
