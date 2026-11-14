# Projet DevSecOps AWS : Secure Cloud Storage & CI/CD

![Terraform](https://img.shields.io/badge/Terraform-1.10+-623CE4?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-S3%20%7C%20KMS%20%7C%20IAM-FF9900?logo=amazonaws&logoColor=white)
![Checkov](https://img.shields.io/badge/Security-Checkov-20B2AA?logo=security)
![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?logo=github-actions&logoColor=white)

## Pourquoi ce projet ?
Étudiant en fin d'études en cybersécurité, j'ai conçu ce projet pour me confronter aux réalités du terrain.

Mon objectif avec ce projet est simple : en apprendre toujours plus sur la sécurité Cloud, un domaine qui devient ma passion de jour en jour en construisant de zéro une infrastructure AWS sécurisée, 100 % automatisée avec Terraform et prête pour la production.

J'y ai déployé un coffre-fort numérique (Amazon S3) qui se met à jour tout seul via un pipeline d'intégration continue, avec des contrôles de sécurité bloquants à chaque étape.

---

## Mes choix d'architecture
Pour que ce projet soit solide, je me suis basé sur les bonnes pratiques d'AWS :

*   **Stockage Principal (`aws_s3_bucket`) :** J'ai provisionné un bucket S3 privé avec versioning activé (protection contre la suppression accidentelle et les ransomwares) et une règle de cycle de vie pour nettoyer les téléchargements incomplets.
*   **Le chiffrement (`aws_kms_key`) :** Je ne voulais pas dépendre de la clé par défaut d'AWS. J'ai donc créé ma propre clé de chiffrement (KMS Customer Managed Key) avec rotation annuelle automatique.
*   **La traçabilité & l'audit (`aws_s3_bucket_logging`) :** J'ai créé un deuxième bucket S3 dédié uniquement au stockage des journaux d'accès (Server Access Logs) pour l'analyse forensique. Ce bucket est lui-même durci (blocage public, versioning, chiffrement SSE-S3 `AES256`, rétention de 90 jours) et protégé contre la suppression accidentelle (`prevent_destroy = true`). Une Bucket Policy autorise uniquement le service `logging.s3.amazonaws.com` à y écrire, avec des conditions strictes (`aws:SourceArn` et `aws:SourceAccount`) pour éviter toute attaque de type *Confused Deputy*.
*   **La mémoire Terraform (Remote Backend & Lock) :** Pour éviter les conflits quand GitHub déploie mon code, j'ai déporté le fichier d'état (`terraform.tfstate`) dans un Remote Backend sur S3 avec chiffrement au repos (`encrypt = true`) et verrouillage natif (`use_lockfile = true`).

---

## Sécurité (L'approche DevSecOps)
J'ai intégré la sécurité directement dans mon code et sur l'infrastructure :

1.  **Audit statique bloquant avec Checkov (`soft_fail: false`) :** À chaque `push`, Checkov analyse mon code Terraform avant tout déploiement. En cas de mauvaise configuration, le pipeline échoue immédiatement. Les seules exceptions légitimes liées à l'architecture (comme l'impossibilité pour le bucket de logs de se journaliser lui-même) sont documentées et justifiées dans le fichier `.checkov.yaml`.
2.  **Verrouillage complet (PAB & Bucket Policies) :** Le blocage des accès publics (Public Access Block) est activé sur le bucket principal **et** sur le bucket de logs. En complément, une Bucket Policy sur le coffre-fort principal refuse toute connexion non chiffrée en transit (HTTP interdit via `aws:SecureTransport`) ainsi que tout envoi de fichier (`s3:PutObject`) qui n'utilise pas explicitement le chiffrement `aws:kms`.
3.  **Moindre privilège :** Les droits du pipeline GitHub Actions sont limités au strict minimum nécessaire (`contents: read` côté GitHub et permissions IAM ciblées côté AWS).

---

## Les problèmes rencontrés (et mes solutions)
J'ai déployé cette infrastructure sur un compte AWS soumis à des règles d'entreprise très strictes (AWS Organizations avec des SCP). Je me suis pris des erreurs "403 Access Denied", et j'ai dû trouver des plans B sécurisés :

| Ce que je voulais faire | Action IAM bloquée | Le blocage (Contrainte SCP) | Mon plan B (Fallback) |
| :--- | :--- | :--- | :--- |
| **Me connecter sans mot de passe (Authentification Zero Trust OIDC)** | `iam:CreateOpenIDConnectProvider` | Création d'OIDC interdite | J'ai utilisé des clés d'accès classiques, stockées de manière chiffrée dans les *GitHub Secrets*, en limitant fortement les permissions de mon pipeline. |
| **Scanner les données avec l'IA (Data Loss Prevention - Macie)** | `macie2:EnableMacie` | Activation de Macie interdite | Comme je ne pouvais pas faire de scan de données sensibles (PII), j'ai sécurisé le contenant : chiffrement avancé (**KMS CMK**) obligatoire et journalisation de chaque action sur le bucket (**S3 Access Logs**). |

---

## Mon Pipeline CI/CD
Tout est automatisé. Quand je push mon code sur GitHub, le workflow `.github/workflows/deploy.yml` prend le relais avec les garde-fous suivants :

1.  **Contrôle de concurrence (`concurrency`) :** Empêche deux exécutions simultanées de se chevaucher ou de s'annuler en plein déploiement (`cancel-in-progress: false`).
2.  **Clonage & Authentification :** Récupération du dépôt et connexion sécurisée à AWS.
3.  **Audit de sécurité (Checkov) :** Scan SAST bloquant (`soft_fail: false`) basé sur `.checkov.yaml`.
4.  **Planification (`terraform plan -out=tfplan`) :** Génération et vérification du plan d'exécution avant toute modification réelle.
5.  **Déploiement (`terraform apply -auto-approve tfplan`) :** Application stricte du plan validé.

<img width="1849" height="744" alt="Capture d’écran du 2026-11-14 19-59-57" src="https://github.com/user-attachments/assets/2f001263-a0a2-492a-8e9e-d9f3335d94a3" />

<img width="1033" height="348" alt="Capture d’écran du 2026-11-14 20-21-26" src="https://github.com/user-attachments/assets/e1441602-f862-43f8-80b6-26908dc5860e" />

---

## Tester le projet chez vous
Si vous voulez cloner mon repo et déployer cette architecture sur votre compte AWS :

```bash
# 1. Créez un bucket S3 pour stocker la mémoire Terraform (Backend) et activez le versioning
aws s3 mb s3://<votre-nom-de-bucket-backend> --region eu-north-1
aws s3api put-bucket-versioning --bucket <votre-nom-de-bucket-backend> --versioning-configuration Status=Enabled

# 2. Ajoutez le nom de ce bucket tout en haut du fichier main.tf

# 3. Initialisez le projet (Terraform >= 1.10.0 requis pour le lockfile S3)
terraform init

# 4. Vérifiez ce qui va être créé
terraform plan

# 5. Déployez !
terraform apply
```

---

## Tests négatifs (Validation des garde-fous)

Pour prouver que le pipeline bloque réellement les dérives de sécurité avant qu'elles n'atteignent AWS, j'ai exécuté plusieurs scénarios de tests négatifs sur une branche isolée (`test/security-gates`). 

À chaque fois, l'étape **Checkov (`soft_fail: false`)** a détecté la faille et stoppé le workflow avant même le `terraform plan` :

| Scénario testé | Modification volontaire dans `main.tf` | Règle Checkov déclenchée | Résultat du pipeline |
| :--- | :--- | :--- | :--- |
| **1. Exposition publique** | `block_public_acls = false` sur le bucket principal | `CKV_AWS_53` | **Bloqué** (déploiement annulé) |
| **2. Absence de chiffrement KMS** | Suppression du bloc de chiffrement SSE-KMS | `CKV_AWS_145` | **Bloqué** (déploiement annulé) |
| **3. Désactivation du versioning** | Passage du versioning à `Suspended` | `CKV_AWS_21` | **Bloqué** (déploiement annulé) |
<img width="461" height="234" alt="Capture d’écran du 2026-11-14 20-15-28" src="https://github.com/user-attachments/assets/f999774b-b296-4d88-9087-5fdbe4545ebc" />

<img width="1841" height="870" alt="Capture d’écran du 2026-11-14 20-15-06" src="https://github.com/user-attachments/assets/22218207-f91a-4ac5-9887-54fdcab52617" />


---

## Nettoyage
Pour supprimer l'infrastructure à la fin de vos tests :
* Passez temporairement `prevent_destroy = false` dans le bloc `lifecycle` de `log_bucket` (qui protège les journaux d'audit en conditions normales).
* Exécutez `terraform destroy`, puis videz et supprimez manuellement le bucket du Remote Backend S3 pour éviter toute facturation.
