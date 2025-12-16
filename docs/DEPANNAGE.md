## Problèmes Courants

### 1. "Decryption failed" ou "Vault password invalid"
**Symptôme :** Ansible refuse de se lancer en disant qu'il ne peut pas lire un fichier chiffré.
**Cause :**
1.  Le fichier `.vault_pass` est manquant.
2.  Le mot de passe dans `.vault_pass` est incorrect.
**Solution :**
Recréez le fichier avec le bon secret :
```bash
echo "LE_VRAI_SECRET" > .vault_pass
```

### 2. "Authentication failed" (SSH Linux)
**Symptôme :** Impossible de se connecter aux VMs Linux.
**Vérifications :**
- Votre clé publique SSH est-elle bien dans `/home/svc-ansible/.ssh/authorized_keys` sur la cible ?
- L'utilisateur défini dans `ansible.cfg` (`remote_user`) est-il le bon ?

### 3. "WinRM TransportError" (Windows)
**Symptôme :** Ansible n'arrive pas à contacter une VM Windows.
**Solution :**
Vérifiez que le script de configuration WinRM a bien été lancé sur la VM Windows :
```powershell
# Sur la VM Windows (PowerShell Admin)
$url = "[https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1](https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1)"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"
(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
powershell.exe -ExecutionPolicy ByPass -File $file
```

### 4. Inventaire Vide
**Symptôme :** `ansible-inventory --graph` ne renvoie aucun hôte.
**Cause :** Problème de connexion avec Xen Orchestra.
**Solution :**
- Vérifiez que l'API XO est accessible.
- Vérifiez que le mot de passe dans `inventory/xo.xen_orchestra.yml` est correct (via `ansible-vault edit`).
- Vérifiez les tags sur vos VMs dans XO (elles doivent avoir `Linux` ou `Windows`).
