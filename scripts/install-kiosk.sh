#!/bin/bash

# ==============================================================================
# INSTALLATEUR MODE KIOSK ANSIBLE
# ==============================================================================

# Vérification Root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Ce script doit être lancé avec SUDO."
  exit 1
fi

# --- 1. DÉTECTION DES CHEMINS ---
# On récupère le dossier où se trouve ce script d'installation
INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# On définit la racine du projet (Si ANSIBLE_ROOT n'est pas défini, on prend le dossier courant)
ANSIBLE_DIR="${ANSIBLE_ROOT:-$INSTALL_DIR}"

# Chemins cibles
MENU_SCRIPT_PATH="/usr/local/bin/ansible-menu"
DOC_DIR="$ANSIBLE_DIR/docs"
README_PATH="$ANSIBLE_DIR/README.md"

echo "=== DÉPLOIEMENT DU MODE KIOSK ==="
echo "📂 Racine du projet détectée : $ANSIBLE_DIR"

# ==============================================================================
# --- 2. GÉNÉRATION DU MENU SYSTÈME (/usr/local/bin/ansible-menu) ---
# ==============================================================================
echo "🔹 Génération du script menu..."

cat > "$MENU_SCRIPT_PATH" <<EOF
#!/bin/bash

# --- CONFIGURATION UNIVERSELLE ---
# Ces variables sont remplacées par install_kiosk.sh lors de l'installation
# Si vous créez ce fichier manuellement, remplacez-les par vos propres chemins
export ANSIBLE_ROOT="${ANSIBLE_DIR}"
export SCRIPTS_DIR="\$ANSIBLE_ROOT/scripts"

# Empêcher l'utilisateur de faire Ctrl+C pour sortir du script (Sécurité Kiosk)
trap '' SIGINT SIGQUIT SIGTSTP

# Couleurs
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Fonction pour exécuter un script ou une commande
run_tool() {
    local script_path="\$1"
    local require_sudo="\$2"

    # On exporte la racine pour que les sous-scripts sachent où ils sont
    export ANSIBLE_ROOT
    
    if [ -f "\$script_path" ]; then
        # On rend exécutable si besoin
        if [ ! -x "\$script_path" ]; then chmod +x "\$script_path"; fi
        
        # Gestion du mode SUDO (nécessaire pour Cron, etc.)
        if [ "\$require_sudo" == "true" ]; then
            echo -e "\${YELLOW}🔒 Ce script nécessite des droits d'administration (sudo).\${NC}"
            # -E préserve les variables d'environnement (comme ANSIBLE_ROOT)
            sudo -E "\$script_path"
        else
            "\$script_path"
        fi
    else
        echo -e "\${RED}Erreur : Script introuvable (\$script_path)\${NC}"
        read -p "Appuyez sur Entrée..."
    fi
}

while true; do
    clear
    echo -e "\${BLUE}#############################################\${NC}"
    echo -e "\${BLUE}#      ANSIBLE CONTROLLER - MENU PRINCIPAL  #\${NC}"
    echo -e "\${BLUE}#############################################\${NC}"
    echo -e "\${BLUE}#  Racine : \$ANSIBLE_ROOT \${NC}"
    echo ""
    echo -e "  \${GREEN}1.\${NC} 🚀 Lancer un Playbook          (Launcher)"
    echo -e "  \${GREEN}2.\${NC} ⏰ Gérer les Tâches Cron       (Planificateur) \${YELLOW}[SUDO]\${NC}"
    echo -e "  \${GREEN}3.\${NC} 🔐 Gestion des Secrets         (Vault)"
    echo -e "  \${GREEN}4.\${NC} 🌍 Explorateur d'Inventaire    (Inventory)"
    echo -e "  \${GREEN}5.\${NC} 👥 Gestion Active Directory    (AD Manager)"
    echo -e "  \${GREEN}6.\${NC} 🛠️  Shell Ansible Rapide        (Nano/Git...)"
    echo -e "  \${GREEN}7.\${NC} ➕ Créer un nouveau Rôle       (Générateur)"
    echo ""
    echo "---------------------------------------------"
    echo -e "  [\${YELLOW}admin\${NC}] 🔓 Déverrouillage Admin     (Shell Définitif)"
    echo -e "  [\${RED}exit\${NC}]  🚪 Déconnexion"
    echo "---------------------------------------------"
    echo ""
    read -r -p "Votre choix > " choice

    case "\$choice" in
        1)
            run_tool "\$SCRIPTS_DIR/launcher.sh"
            ;;
        2)
            # Cron a besoin de sudo pour modifier /var/spool/cron/ ou les fichiers système
            if [ -f "\$SCRIPTS_DIR/manage_ansible_cron.sh" ]; then
                run_tool "\$SCRIPTS_DIR/manage_ansible_cron.sh" "true"
            else
                run_tool "\$SCRIPTS_DIR/manage_cron.sh" "true"
            fi
            ;;
        3)
            # --- CORRECTION : Utilisation de SCRIPTS_DIR ---
            run_tool "\$SCRIPTS_DIR/vault_manager.sh"
            ;;
        4)
            run_tool "\$SCRIPTS_DIR/inventory_tool.sh"
            ;;
        5)
            run_tool "\$SCRIPTS_DIR/ad_manager.sh"
            ;;
        6)
            # --- SHELL SURVEILLÉ (Sous-dossiers OK, Sortie bloquée) ---
            echo -e "\\n\${GREEN}>>> Ouverture du shell dans \$ANSIBLE_ROOT\${NC}"
            echo -e "\${GREY}Tapez 'exit' pour revenir au menu.\${NC}"
            echo "------------------------------------------------"
            
            cd "\$ANSIBLE_ROOT" || echo "Erreur dossier"

            # 1. On autorise Ctrl+C pour les commandes du shell
            trap - SIGINT SIGQUIT SIGTSTP

            # 2. Configuration dynamique du shell pour empêcher la sortie du dossier
            # SKIP_ANSIBLE_MENU=1 est crucial pour que le .bashrc ne relance pas le menu
            RC_CONFIG="
                SKIP_ANSIBLE_MENU=1
                . ~/.bashrc
                export ANSIBLE_ROOT=\"\$ANSIBLE_ROOT\"
                
                check_path() {
                    # Si le chemin actuel ne commence pas par ANSIBLE_ROOT, on revient à la maison
                    if [[ \"\\\$PWD\" != \"\$ANSIBLE_ROOT\" && \"\\\$PWD\" != \"\$ANSIBLE_ROOT\"/* ]]; then
                        echo -e \"\\n\\033[0;31m⛔ Sortie de périmètre interdite.\\033[0m\"
                        cd \"\$ANSIBLE_ROOT\"
                    fi
                }
                
                export PROMPT_COMMAND=check_path
                export PS1='(Ansible) \[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
            "

            # 3. Lancement du shell temporaire
            bash --rcfile <(echo "\$RC_CONFIG")

            # 4. Retour au menu -> re-blocage des signaux
            trap '' SIGINT SIGQUIT SIGTSTP
            ;;
        7)
            # Création de rôle : On force le dossier racine pour que le rôle soit créé au bon endroit
            echo -e "\\n\${GREEN}>>> Lancement du générateur de rôle\${NC}"
            cd "\$ANSIBLE_ROOT" || echo "Erreur dossier"
            
            # On lance le script s'il existe en utilisant SCRIPTS_DIR
            if [ -f "\$SCRIPTS_DIR/create_role.sh" ]; then
                # On ne met pas "true" pour sudo, car créer un rôle ne devrait pas nécessiter root
                "\$SCRIPTS_DIR/create_role.sh"
            else
                echo -e "\${RED}Script de création introuvable (\$SCRIPTS_DIR/create_role.sh)\${NC}"
            fi
            
            echo ""
            read -p "Appuyez sur Entrée pour revenir au menu..."
            ;;

        admin|shell)
            echo -e "\\n\${YELLOW}🔓 Veuillez saisir votre mot de passe pour quitter le menu définitivement :\${NC}"
            # On utilise 'su' pour vérifier le mot de passe système de l'utilisateur courant
            if su -c "true" "\$USER"; then
                echo -e "\${GREEN}Accès autorisé.\${NC}"
                trap - SIGINT SIGQUIT SIGTSTP
                
                # Variable clé pour dire au .bashrc de ne PAS relancer le menu
                export SKIP_ANSIBLE_MENU=1
                export ANSIBLE_ROOT
                
                cd "\$ANSIBLE_ROOT" || echo "Erreur dossier"
                
                # exec remplace le processus menu par bash => pas de retour possible
                exec bash
            else
                echo -e "\${RED}❌ Mot de passe incorrect.\${NC}"
                sleep 2
            fi
            ;;
        exit|quit|q)
            echo "Déconnexion..."
            kill -9 \$PPID
            ;;
        *)
            echo "Choix invalide."
            sleep 0.5
            ;;
    esac
done
EOF

# Rendre exécutable
chmod +x "$MENU_SCRIPT_PATH"
echo "✅ Script installé : $MENU_SCRIPT_PATH"

# ==============================================================================
# --- 3. GÉNÉRATION DOCUMENTATION ---
# ==============================================================================
echo "🔹 Mise à jour de la documentation..."
mkdir -p "$DOC_DIR"

cat > "$DOC_DIR/MODE_KIOSK.md" <<EOF
# Documentation du Mode Kiosk

## 📂 Emplacement Dynamique
* **Racine Projet :** \`$ANSIBLE_DIR\`
* **Scripts Outils :** \`$ANSIBLE_DIR/scripts\`
* **Menu Système :** \`/usr/local/bin/ansible-menu\`

## 🛠️ Fonctionnement
Le menu pointe automatiquement vers les scripts situés dans le dossier \`scripts/\` de la racine.
L'option "Gérer les Tâches Cron" déclenche automatiquement une demande de droits \`sudo\`.

## 🔐 Sécurité
* **Verrouillage Ctrl+C** : Activé par défaut.
* **Shell Restreint** : Borné au dossier racine.
EOF

echo "✅ Docs générées."

# Mise à jour README.md si nécessaire
if [ -f "$README_PATH" ]; then
    if ! grep -q "Mode Kiosk" "$README_PATH"; then
        cat >> "$README_PATH" <<EOF

---
## 🖥️ Mode Kiosk (Menu Interactif)
Pour éviter de taper des commandes manuelles, un **Menu d'Administration** centralisé est disponible.
Lancez-le manuellement avec la commande : \`ansible-menu\`
EOF
        echo "✅ README.md mis à jour."
    else
        echo "ℹ️  README.md déjà à jour."
    fi
fi

# ==============================================================================
# --- 4. CONFIGURATION .BASHRC ---
# ==============================================================================

# Trouver le vrai utilisateur (SUDO_USER) ou l'utilisateur courant
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
BASHRC="$USER_HOME/.bashrc"

echo "🔹 Configuration du .bashrc pour l'utilisateur : $REAL_USER ($USER_HOME)"

if [ -f "$BASHRC" ]; then
    if grep -q "SKIP_ANSIBLE_MENU" "$BASHRC"; then
        echo "ℹ️  .bashrc déjà configuré."
    else
        cat >> "$BASHRC" <<'EOF'

# --- Lancement automatique du Menu Ansible ---
if [[ $- == *i* ]] && [ -z "$SKIP_ANSIBLE_MENU" ]; then
    if command -v ansible-menu &> /dev/null; then
        ansible-menu
    fi
fi
EOF
        echo "✅ .bashrc configuré pour le lancement automatique."
    fi
else
    echo "⚠️  Fichier .bashrc introuvable pour $REAL_USER."
fi

echo ""
echo "🎉 Installation terminée ! Tapez 'ansible-menu' pour tester."

# ==============================================================================
# --- 5. EFFACEMENT ---
# ==============================================================================
echo "Effacement de l'installateur..."
rm -- "$0"
