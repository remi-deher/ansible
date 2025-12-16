# Ansible Infrastructure & Mode Kiosk

Ce dépôt contient l'ensemble du code "Infrastructure as Code" (IaC) pour gérer le parc informatique (Linux & Windows) de manière centralisée, sécurisée et modulaire.

L'architecture a été modernisée pour être **portable** : le projet peut être cloné dans n'importe quel dossier, les scripts s'adapteront automatiquement grâce à la détection dynamique de la racine (`ANSIBLE_ROOT`).

---

## 🚀 Démarrage Rapide

### 1. Pré-requis
* **Ansible** installé sur votre machine de contrôle :
  ```bash
  sudo apt update && sudo apt install ansible -y
  ```
* **Accès SSH** configuré vers les serveurs cibles (clé publique déployée).
* **Mot de passe Vault** : Récupérez le mot de passe secret.

### 2. Configuration de la Sécurité
Ansible a besoin du mot de passe pour déchiffrer les variables sensibles du projets.
Créez le fichier `.vault_pass` à la racine du projet :
```bash
echo "LE_MOT_DE_PASSE_SECRET" > .vault_pass
```
> **⚠️ SÉCURITÉ :** Ce fichier est ignoré par Git. Ne le commitez jamais !

### 3. Installation du Mode Kiosk (Recommandé)
Le Mode Kiosk installe un menu système (`ansible-menu`) et configure l'environnement.
```bash
# Rendre le script d'installation exécutable (si présent)
chmod +x install_kiosk.sh

# Lancer l'installation (nécessite sudo pour créer le menu dans /usr/local/bin)
sudo ./install_kiosk.sh
```

---

## 📂 Architecture du Projet

Le projet sépare strictement les outils techniques (scripts) de la logique métier (playbooks).

```text
.
├── ansible.cfg            # Configuration Ansible locale
├── .vault_pass            # Secret (Ignoré par Git)
├── docs/                  # Documentation technique générée
├── scripts/               # 🛠️ OUTILS D'ADMINISTRATION (Portable)
│   ├── launcher.sh        # Lanceur de playbooks avec recherche fzf
│   ├── vault_manager.sh   # Gestionnaire de secrets simplifiés
│   ├── manage_cron.sh     # Planificateur de tâches (Interface Cron)
│   ├── ad_manager.sh      # Gestion utilisateurs AD
│   └── inventory_tool.sh  # Explorateur d'inventaire dynamique
├── inventory/             # Inventaires (Hosts statiques & Plugin XO)
├── group_vars/            # Variables par groupe (All, Linux, Windows...)
├── roles/                 # Briques logiques réutilisables (Nginx, AD, Common...)
├── playbooks/             # Scénarios d'orchestration (Update, Deploy...)
└── files/                 # Fichiers statiques (Certificats, Configs...)
```

### 🏗️ Portabilité & Variables
Ce projet n'utilise pas de chemins absolus codés en dur.
* **Variable Universelle :** `$ANSIBLE_ROOT`
* **Fonctionnement :**
    * Si lancé via le menu : Le menu définit la racine et l'exporte.
    * Si lancé manuellement : Chaque script dans `scripts/` calcule dynamiquement sa position relative.

---

## 🖥️ Mode Kiosk (Menu Interactif)

Un **Menu d'Administration** centralisé est disponible pour éviter les erreurs de syntaxe manuelles.

### Lancement
Tapez simplement la commande suivante (ou connectez-vous en SSH si configuré) :
```bash
ansible-menu
```

### Fonctionnalités du Menu
1.  🚀 **Lancer un Playbook :** Liste interactive des playbooks disponibles.
2.  ⏰ **Tâches Cron :** Interface visuelle pour planifier les playbooks (Le menu gère l'élévation `sudo` automatiquement).
3.  🔐 **Vault Manager :** Chiffrer/Déchiffrer/Éditer les secrets.
4.  🌍 **Inventaire :** Visualiser le graphe des groupes et tester le ping.
5.  👥 **Active Directory :** Création d'utilisateurs, Reset MDP.
6.  🛠️ **Shell Sécurisé :** Terminal borné au dossier Ansible (Navigation hors dossier bloquée).

### ⚠️ Configuration Manuelle (.bashrc)
Si vous n'avez pas utilisé l'installateur automatique, ajoutez ceci à votre `~/.bashrc` pour activer le menu sans créer de boucle infinie :

```bash
# --- Lancement automatique du Menu Ansible ---
# La variable SKIP_ANSIBLE_MENU est essentielle pour le mode Admin
if [[ $- == *i* ]] && [ -z "$SKIP_ANSIBLE_MENU" ]; then
    if command -v ansible-menu &> /dev/null; then
        ansible-menu
    fi
fi
```

---

## 🛠️ Utilisation des Playbooks (Manuelle)

Les playbooks peuvent être lancés manuellement depuis la racine avec `ansible-playbook`.

### 🐧 Maintenance Système (Linux)
Mise à jour des paquets, durcissement SSH, installation des outils de base et UFW.
```bash
ansible-playbook playbooks/update_systems.yml
```

### 👁️ Monitoring & Inventaire
Installation et configuration des agents **Zabbix** et **GLPI**.
```bash
ansible-playbook playbooks/deploy_monitoring.yml
```

### 🌐 Stack Web (Heimdall)
Déploiement complet : Nginx + PHP + Application Dashboard Heimdall.
```bash
ansible-playbook playbooks/manage_web.yml
```

### 🔐 Certificats & RDP Gateway
1. **Certificats CA :** Déploiement des racines de confiance sur tout le parc.
2. **Gateway RDP :** Mise à jour complexe du certificat SSL sur la Gateway Windows (IIS/WMI/UDP).
```bash
ansible-playbook playbooks/update_rd_gateway.yml
```

---

## 🔑 Gestion des Secrets

Pour éditer les variables chiffrées (mots de passe API, comptes de services...) :

**Via le script (Recommandé) :**
```bash
./scripts/vault_manager.sh
```

**Via la commande standard :**
```bash
ansible-vault edit group_vars/all.yml
```

---

## 📝 Développement

###  **Ne modifiez pas** le script système `/usr/local/bin/ansible-menu`.

**Pour ajouter une fonctionnalité :**

1.  Créez un nouveau **Rôle** dans `roles/` (ex: `roles/docker`).
```bash
mkdir -p roles/mon_nouveau_role/{tasks,handlers,defaults,templates}
```
2.  Créez un playbook dans `playbooks/` qui appelle ce rôle.
3.  Le nouveau playbook apparaîtra automatiquement dans le Menu Kiosk (Option 1).

---
**Mainteneur :** DEHER Rémi
