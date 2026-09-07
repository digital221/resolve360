# Rapport d'Audit & Guide de Déploiement — Résolve360

**Date :** 7 Septembre 2026  
**Édition :** Enterprise White-Label  
**Domaine de Production :** `https://reclam.digitalfactory.sn`  
**Éditeur / Développeur :** Digital Factory SN (`support@digitalfactory.sn`)  

---

## Executive Summary

Cet audit exhaustif et ce guide d'automatisation formalisent le rebrand complet de la plate-forme **OTOBO** vers **Résolve360** (Solution bancaire et institutionnelle de gestion des réclamations et du service client).

Toutes les configurations, modifications de base de données, gabarits HTML/TT, corrections de bogues de configuration et composants visuels ont été regroupés sous forme d'un **Système de Seed Automatisé** hébergé dans le projet local `banksla`.

---

## 1. Synthèse de l'Audit Système & Rebranding

| Élément / Composant | État Avant Audit | État Après Modification & Seed | Status |
| :--- | :--- | :--- | :---: |
| **ProductName (SysConfig)** | `"OTOBO"` | `"Résolve360"` | ✅ CONFORME |
| **Secure::DisableBanner** | Syntaxe corrompue (Texte brut au lieu d'un boolean) | Boolean YAML valide (`--- '1'\n`) — Masquage des bannières OTOBO | ✅ CORRIGÉ |
| **Ticket #1 de Bienvenue** | Mentionne "Welcome to OTOBO community!" & Rother OSS | *"Bienvenue sur Résolve360 !"* avec coordonnées Digital Factory SN | ✅ CONFORME |
| **Portail Client (`/customer.pl`)** | Logo & Textes OTOBO par défaut | Logo SVG SVG/Vector Résolve360 + Footer *Digital Factory SN* | ✅ CONFORME |
| **Widgets Dashboard Agent (`/akcil`)** | Feed RSS OTOBO, IFrame otobo.org, Image OTOBO | Widgets externes désactivés via `ZZZAResolve360.pm` | ✅ CONFORME |
| **Liens externes de navigation** | Menu *"Jump to OTOBO!"* | Liens externes supprimés | ✅ CONFORME |
| **Language File (`fr.pm`)** | Warning de constante flottante à la ligne 10890 | Syntaxe Perl `fr.pm` corrigée et nettoyée | ✅ CORRIGÉ |
| **Nginx Proxy Manager** | Config standard | Filtres de substitution d'en-têtes et proxying HTTPS | ✅ CONFORME |

---

## 2. Structure des Seeds de Déploiement (`otobo-setup/`)

Le dossier `otobo-setup/` à la racine de `banksla` contient l'ensemble des scripts et fichiers nécessaires pour déployer ou ré-appliquer automatiquement le branding sur n'importe quel serveur ou instance cliente :

```
/Users/daoudafall/Documents/banksla/otobo-setup/
├── install-otobo.sh           # Orchestrateur d'installation (Docker + Nginx + DB + Seed)
├── seed.sh                    # Script principal d'injection de seed et branding
├── configs/
│   ├── ZZZAResolve360.pm      # Fichier Perl de configuration Kernel (Product, Widgets, Security)
│   └── nginx-proxy.conf       # Configuration Nginx Proxy Manager avec sub_filters
└── templates/
    ├── CustomerLogin.tt       # Page de connexion Client (Branding Résolve360)
    ├── CustomerFooter.tt      # Pied de page Client (Résolve360 — Digital Factory SN)
    ├── Header.tt              # En-tête interface Agent/Admin
    ├── Footer.tt              # Pied de page interface Agent/Admin
    └── Login.tt               # Connexion interface Agent/Admin
```

---

## 3. Utilisation des Scripts de Déploiement

### Exécution du Seed sur une instance existante

Pour appliquer ou mettre à jour la configuration Résolve360 sur un serveur en production ou staging :

```bash
cd /Users/daoudafall/Documents/banksla/otobo-setup

./seed.sh \
  --project otobo-reclam \
  --client "Résolve360" \
  --fqdn "reclam.digitalfactory.sn" \
  --db-pass "OtoboDB_Root_2024!"
```

### Options supportées par `seed.sh` :

- `--project` : Nom du projet Docker Compose (défaut : `otobo-reclam`)
- `--db-pass` : Mot de passe root MariaDB
- `--client` : Nom de l'organisation ou du produit (défaut : `Résolve360`)
- `--fqdn` : Nom de domaine de l'instance (ex : `reclam.banque.sn`)
- `--dry-run` : Mode simulation sans modification réelle

---

## 4. Points d'Attention Technique & Troubleshooting

1. **Format YAML dans `sysconfig_default` :**  
   Les variables de configuration de type Checkbox dans la base de données MariaDB nécessitent la structure YAML exacte `--- '1'\n`. Un texte brut provoque des erreurs lors de la réécriture de `ZZZAAuto.pm` par `otobo.Console.pl Maint::Config::Rebuild`.

2. **Fichier Kernel d'extension (`Kernel/Config/Files/User/ZZZAResolve360.pm`) :**  
   Toutes les surcharges de configuration (`ProductName`, désactivation des widgets RSS/Iframe OTOBO, etc.) doivent résider dans le sous-dossier `User/` pour être persistantes après les mises à jour majeures du conteneur Web.

3. **Invalidation du Cache :**  
   Après toute modification de template ou de configuration Kernel, exécuter systématiquement :
   ```bash
   docker exec otobo-reclam-web-1 /opt/otobo/bin/otobo.Console.pl Maint::Config::Rebuild
   docker exec otobo-reclam-web-1 /opt/otobo/bin/otobo.Console.pl Maint::Cache::Delete
   ```

---

## 5. Horodatage & Validation

- **Vérification du Seed sur Serveur :** Succès 100% (DB, Configs, Templates, Cache).
- **Prochaine étape conseillée :** Exécuter un commit Git sur la branche principale du repo `banksla`.
