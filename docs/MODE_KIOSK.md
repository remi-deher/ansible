# Documentation du Mode Kiosk (Menu Interactif)

Le "Mode Kiosk" est une interface textuelle (TUI) conçue pour sécuriser et simplifier l'usage du serveur Ansible. Il agit comme un "Wrapper" autour des scripts et commandes Ansible.

## 📂 Emplacement
* **Script système :** `/usr/local/bin/ansible-menu`
* **Dossier projet :** `/opt/ansible`

## 🚀 Fonctionnalités du Menu

### 1. Lancer un Playbook (Launcher)
Affiche la liste des playbooks présents dans `playbooks/`.
* Utilise `fzf` (si installé) pour une recherche rapide.
* Gère automatiquement le chargement de `ansible.cfg` et les chemins relatifs.

### 2. Gérer les Tâches Cron
Interface visuelle pour planifier l'exécution des playbooks.
* Permet d'ajouter, modifier ou supprimer des tâches planifiées.

### 3. Gestion des Secrets (Vault)
* Scanne le projet pour trouver les fichiers chiffrés (`$ANSIBLE_VAULT...`).
* Permet d'éditer, chiffrer ou déchiffrer via un menu simple.

### 4. Explorateur d'Inventaire
Outil de diagnostic pour l'inventaire dynamique.
* **Graph :** Affiche l'arborescence des groupes.
* **Ping :** Teste la connectivité.

### 5. Gestion Active Directory
Lance le script de gestion AD (Création users, Reset password...).

### 6. Shell Ansible Rapide
Ouvre un terminal temporaire borné au dossier `/opt/ansible`.
* **Surveillance :** L'utilisateur peut aller dans les sous-dossiers (`playbooks`, `roles`...) mais s'il tente de remonter plus haut (ex: `cd /etc`), il est automatiquement ramené à la racine du projet.
* **Retour :** La commande `exit` renvoie au menu principal.

## 🔐 Sécurité

### Verrouillage des Signaux
Le script capture les signaux `Ctrl+C` et `Ctrl+Z` pour empêcher la sortie accidentelle.

### Mode Admin (Déverrouillage)
Pour effectuer des tâches de maintenance système :
1.  Choisir l'option **[admin]**.
2.  Saisir le mot de passe de l'utilisateur.
3.  Cela ouvre un shell définitif et désactive le menu.
