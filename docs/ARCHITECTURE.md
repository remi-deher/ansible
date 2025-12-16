## Vue d'ensemble
Ce dépôt centralise la gestion de configuration pour l'ensemble du parc informatique (Linux et Windows).
Il repose sur le principe **"Push"** : le contrôleur Ansible se connecte aux machines via SSH (Linux) ou WinRM (Windows) pour appliquer les configurations.

## Flux de Données

### 1. Inventaire Dynamique (Xen Orchestra)
L'inventaire n'est pas statique.
- Le plugin `inventory/xo.xen_orchestra.yml` interroge l'API de Xen Orchestra.
- Il récupère les VMs et les trie automatiquement dans des groupes basés sur leurs **Tags** XO :
    - Tag `Linux` -> Groupe `linux`
    - Tag `Windows` -> Groupe `windows`
    - Tag `AD` -> Groupe `windows` (spécifique AD)

### 2. Gestion des Secrets (Vault)
- **Problème :** Nous devons stocker des mots de passe (API XO, Admin Local) dans Git.
- **Solution :** Ansible Vault chiffre les fichiers sensibles (AES256).
- **Fonctionnement :**
    - Clé de déchiffrement : `.vault_pass` (stocké localement, ignoré par Git).
    - Fichiers chiffrés : `inventory/xo.xen_orchestra.yml`, `group_vars/all.yml`.

### 3. Gateway RDP (Flux Complexe)
La mise à jour du certificat RDP Gateway suit un chemin spécifique orchestré par `playbooks/update_rd_gateway.yml` :
1.  **Zoraxy (Linux)** : Ansible récupère le certificat Let's Encrypt généré par le reverse proxy.
2.  **Control Node (Local)** : Ansible convertit le certificat `.pem` + `.key` en format Windows `.pfx` via OpenSSL.
3.  **Windows Server** : Ansible pousse le `.pfx`, l'importe dans le magasin `LocalMachine\My`, et met à jour les bindings (IIS, WMI Terminal Services, et Listener UDP).

## Structure des Rôles

Chaque rôle est une unité fonctionnelle indépendante.

| Rôle | Description | OS Cible |
| :--- | :--- | :--- |
| **common** | Socle de base (Updates, UFW, Outils admin). Doit être exécuté partout. | Linux |
| **ad_management** | Wrapper autour des modules PowerShell pour gérer l'AD. | Windows |
| **heimdall** | Déploie le dashboard. Dépend de `nginx` et `php`. | Linux |
| **rd_gateway** | Logique complexe de certificats RDP. | Windows |
| **certificates** | Déploie les CA racines d'entreprise. | Tous |
