# Résolve360

**Plateforme de Gestion des Réclamations Bancaires**  
Powered by [OTOBO](https://otobo.de) | Built by [Digital Factory SN](https://digitalfactory.sn)

---

## 🎯 À propos

**Résolve360** est une solution complète de gestion des réclamations clients pour le secteur bancaire et financier en Afrique de l'Ouest. Elle est basée sur OTOBO (open-source ticket system) et configurée pour la conformité aux normes **ISO 10002** et aux directives **BCEAO**.

## 🌐 Accès

| Interface | URL |
|-----------|-----|
| 👤 Portail Client | https://reclam.digitalfactory.sn/otobo/customer.pl |
| 🧑‍💼 Interface Agent | https://reclam.digitalfactory.sn/otobo/index.pl |
| ⚙️ Administration | https://reclam.digitalfactory.sn/otobo/index.pl?Action=Admin |

## 🏗️ Architecture

```
├── docker/                  # Configuration Docker OTOBO
│   ├── docker-compose.yml
│   └── .env.example
├── otobo-setup/             # Scripts d'installation et de configuration
│   ├── install-otobo.sh
│   ├── configure-queues.sh
│   └── configure-sla.sh
├── config/                  # Fichiers de configuration OTOBO
│   ├── SysConfig/           # Paramètres système exportés
│   ├── Queues/              # Définitions des files d'attente
│   └── SLA/                 # Accords de niveau de service
└── docs/                    # Documentation
    ├── installation.md
    ├── configuration.md
    └── user-guide.md
```

## ⚡ Stack technique

- **Backend** : OTOBO 11.x (Perl/Plack)
- **Base de données** : MariaDB LTS
- **Recherche** : Elasticsearch
- **Reverse Proxy** : Nginx Proxy Manager (OpenResty)
- **Conteneurs** : Docker Compose
- **Serveur** : VPS Linux (Ubuntu)

## 📋 Fonctionnalités

### Gestion des Réclamations
- ✅ Portail client multilingue (FR/EN/Wolof)
- ✅ Dépôt de réclamations multi-canal (web, email, agent)
- ✅ Suivi temps réel avec numéro de référence
- ✅ Pièces jointes et preuves documentaires

### SLAs Bancaires (ISO 10002 / BCEAO)
- ✅ Accusé de réception : **24h**
- ✅ Traitement standard : **30 jours ouvrés**
- ✅ Urgences fraude : **5 jours ouvrés**
- ✅ Escalade automatique avant expiration

### Catégories couvertes
- 🏦 Fraude & Sécurité
- 💳 Cartes & Paiements
- 💸 Virement & Transfert
- 🏠 Crédit & Prêts
- 📱 Banque Mobile/Web
- 🏢 Service Agence

## 🚀 Installation rapide

```bash
git clone https://github.com/digtal221/resolve360.git
cd resolve360

# Configurer les variables d'environnement
cp docker/.env.example docker/.env
# Éditer docker/.env avec vos valeurs

# Démarrer
cd docker && docker compose up -d
```

## 📄 Licence

Projet propriétaire — Digital Factory SN © 2024  
OTOBO est sous licence GNU GPL v3.
