# Enterprise AWS DevSecOps : Secure Cloud Storage & CI/CD

![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-S3%20%7C%20KMS%20%7C%20IAM-FF9900?logo=amazonaws&logoColor=white)
![Checkov](https://img.shields.io/badge/Security-Checkov-20B2AA?logo=security)
![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?logo=github-actions&logoColor=white)

## Contexte du Projet
Ce projet illustre la conception, la sécurisation et le déploiement 100% automatisé d'une infrastructure de stockage cloud sur Amazon Web Services (AWS). Conçu selon l'approche **Infrastructure as Code (IaC)** avec Terraform, il intègre des pratiques **DevSecOps** pour garantir un déploiement sécurisé, auditable et prêt pour la production.

L'objectif est de provisionner un coffre-fort numérique (Amazon S3) hautement sécurisé, déployé exclusivement via un pipeline d'intégration continue avec validation de sécurité automatisée .

---

## Architecture Technique
L'infrastructure repose sur des services AWS managés, configurés selon les principes du **Well-Architected Framework** :

*   **Stockage Principal (`aws_s3_bucket`) :** Compartiment S3 privé agissant comme un coffre-fort, protégé contre les suppressions accidentelles et les ransomwares (Versioning).
*   **Chiffrement Avancé (`aws_kms_key`) :** Utilisation d'une clé **KMS Customer Managed Key (CMK)** avec rotation automatique annuelle, remplaçant la clé AWS par défaut pour un contrôle total du cycle de vie cryptographique.
*   **Audit & Traçabilité (`aws_s3_bucket_logging`) :** Création d'un second compartiment S3 dédié exclusivement à la centralisation des journaux d'accès (Server Access Logs) pour l'analyse forensique.
*   **Gestion de l'État Terraform (Remote State) :** Centralisation du fichier `terraform.tfstate` dans un **Remote Backend S3** pour garantir l'idempotence, prévenir les conflits de déploiement et sécuriser les métadonnées de l'infrastructure.

---

## Sécurité & Hardening (DevSecOps)
La sécurité est intégrée à la fois dans le code (Shift-Left) et sur l'infrastructure (Hardening) :

1.  **Analyse Statique (SAST) avec Checkov :** Le code HCL est scanné à chaque `push` par Bridgecrew Checkov pour détecter et bloquer les vulnérabilités de configuration avant même le déploiement sur AWS.
2.  **Public Access Block (PAB) :** Application stricte des règles de blocage public au niveau du bucket S3, prévenant toute exposition de données suite à une erreur humaine.
3.  **Principe du Moindre Privilège :** Les accès GitHub Actions sont restreints au strict minimum nécessaire via des politiques IAM ciblées.

---

## Contraintes Organisationnelles (SCP) & Fallbacks
Ce projet a été déployé sur un environnement AWS soumis à des **Service Control Policies (SCP)** strictes gérées via *AWS Organizations* (simulant un environnement bancaire ou de grande entreprise très régulé). Face à des erreurs `403 AccessDeniedException`, des solutions de contournement ont été implémentées :

| Fonctionnalité Prévue | Action IAM Bloquée | Contrainte SCP | Solution Implémentée (Fallback) |
| :--- | :--- | :--- | :--- |
| **Authentification Zero Trust** | `iam:CreateOpenIDConnectProvider` | OIDC Interdit | Utilisation de GitHub Secrets chiffrés pour les Access Keys, combinée à des permissions restreintes. |
| **Data Loss Prevention (DLP)** | `macie2:EnableMacie` | Amazon Macie Interdit | Renforcement de la sécurité préventive via le chiffrement avancé (KMS CMK) et le traçage complet (S3 Access Logs) en l'absence de scan PII. |

---

## CI/CD Pipeline (GitHub Actions)
Le fichier `.github/workflows/deploy.yml` orchestre le déploiement à chaque modification de la branche `main` :

1.  **Checkout :** Clonage du dépôt.
2.  **Authentication :** Connexion sécurisée à AWS.
3.  **Security Scan :** Audit de l'infrastructure via Checkov.
4.  **Setup Terraform :** Installation de l'environnement HashiCorp.
5.  **Provisioning :** Exécution automatisée de `terraform init` (connexion au Remote Backend) et `terraform apply -auto-approve`.

---

##  Déploiement & Reproductibilité
Pour reproduire cette infrastructure dans votre environnement AWS :

```bash
# 1. Configurer le bucket S3 pour le Remote Backend
aws s3 mb s3://<votre-nom-de-bucket-backend> --region eu-north-1

# 2. Mettre à jour le bloc "backend s3" dans main.tf avec ce nom de bucket

# 3. Initialiser Terraform (téléchargement des providers et connexion au backend)
terraform init

# 4. Vérifier les ressources prévues
terraform plan

# 5. Déployer l'infrastructure
terraform apply
```
---

## Nettoyage
Exécutez `terraform destroy` et videz manuellement le bucket du Remote Backend à la fin de vos tests pour éviter toute facturation inattendue.
