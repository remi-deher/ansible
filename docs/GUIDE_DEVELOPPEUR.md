Ce guide est destiné à toute personne souhaitant modifier ou ajouter des fonctionnalités à l'infrastructure.

## Règle d'Or : "Pas de modification en direct"
Ne modifiez jamais un serveur à la main (apt install, modif config...).
**Si ce n'est pas dans Ansible, ça n'existe pas.**

## Workflow : Ajouter une nouvelle fonctionnalité

### Étape 1 : Créer un nouveau rôle
Ne mettez pas votre code directement dans un playbook. Créez un rôle modulaire.
```bash
# Exemple : Installation de Docker
mkdir -p roles/docker/{tasks,handlers,defaults}
```

Ou utilisez la commande suivante à la racine du projet
```bash
# Lancez le générateur de rôle
./CreerUnRoleAnsible
```

### Étape 2 : Écrire les tâches (`tasks/main.yml`)
Soyez **idempotent** : votre tâche doit pouvoir être lancée 10 fois sans casser le serveur.
```yaml
# MAUVAIS (Va échouer si déjà installé)
- shell: curl -fsSL [https://get.docker.com](https://get.docker.com) | sh

# BON (Vérifie l'état)
- name: Installer Docker
  apt:
    name: docker.io
    state: present
```

### Étape 3 : Utiliser des variables (`defaults/main.yml`)
Ne mettez jamais de valeurs "en dur" (IPs, versions, chemins) dans les tâches.
```yaml
# roles/docker/defaults/main.yml
docker_version: "latest"
docker_users: ["admin"]
```

### Étape 4 : Créer ou mettre à jour un Playbook
Ajoutez votre rôle dans un playbook existant (ex: `playbooks/update_systems.yml`) ou créez-en un nouveau si c'est une tâche ponctuelle.

### Étape 5 : Tester
Lancez votre playbook sur une machine de test ou avec l'option `--check` (Dry Run).
```bash
ansible-playbook playbooks/mon_playbook.yml --limit ma-vm-test
```

## Bonnes Pratiques

1.  **Noms explicites :** `name: Installer Nginx` est mieux que `name: apt install`.
2.  **Handlers :** Utilisez les handlers pour redémarrer les services uniquement quand la config change.
3.  **Git :** Commitez vos changements avec des messages clairs.
    - `feat: ajout du rôle docker`
    - `fix: correction permission heimdall`
