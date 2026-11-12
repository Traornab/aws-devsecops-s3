# 🛡️ AWS DevSecOps : Architecture Cloud Sécurisée & CI/CD GitOps

![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-S3%20%7C%20KMS%20%7C%20IAM-FF9900?logo=amazonaws&logoColor=white)
![Checkov](https://img.shields.io/badge/Security-Checkov-20B2AA?logo=security)
![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?logo=github-actions&logoColor=white)

## 📌 Présentation du Projet
Ce projet démontre la conception, la sécurisation et le déploiement automatisé d'une infrastructure de stockage sur AWS. Il applique les principes du **DevSecOps** et de l'**Infrastructure as Code (IaC)**, conçus pour répondre aux exigences de sécurité d'une architecture d'entreprise en production.

L'objectif est de provisionner un coffre-fort numérique (S3) hautement sécurisé, auditable, et déployé exclusivement via un pipeline d'intégration continue avec validation de sécurité automatisée (Shift-Left Security).

## 🏗️ Architecture Technique

*   **Stockage Principal :** Bucket S3 privé ("Coffre-fort") avec versioning anti-ransomware.
*   **Audit & Traçabilité :** Bucket S3 dédié exclusivement à la réception des Server Access Logs pour l'analyse forensique.
*   **Chiffrement Avancé :** Utilisation d'une clé **KMS Customer Managed Key (CMK)** avec rotation automatique (au lieu de la clé AWS par défaut).
*   **Gestion de l'État :** Configuration d'un **Remote Backend S3** pour centraliser le `terraform.tfstate`, garantissant l'idempotence et le travail collaboratif.

## 🔒 Implémentation DevSecOps

Le pipeline CI/CD (GitHub Actions) intègre la sécurité à chaque étape du déploiement :
1.  **Linting & Security Scan :** Analyse statique du code Terraform par **Checkov** avant tout déploiement pour bloquer les configurations non conformes.
2.  **Hardening S3 :** Application stricte du *Public Access Block* (PAB) empêchant toute exposition publique accidentelle des données.
3.  **Principe du Moindre Privilège :** IAM restreint pour le rôle de déploiement CI/CD.

## 🚧 Contraintes d'Entreprise & Résolution (Real-World Scenarios)

Dans le cadre de ce déploiement, l'environnement AWS cible était restreint par des **Service Control Policies (SCP)** strictes gérées via AWS Organizations (simulant un environnement bancaire ou très régulé).

*   **Blocage OIDC (Zero Trust) :** 
    *   *Problème :* La SCP `p-t0wxvglw` interdisait l'action `iam:CreateOpenIDConnectProvider`.
    *   *Solution implémentée :* Mise en place d'une authentification par clés d'accès restreintes via GitHub Secrets chiffrés, avec limitation stricte des permissions (`contents: read`).
*   **Blocage Amazon Macie (DLP) :**
    *   *Problème :* Impossibilité d'activer la détection automatique de PII (Data Loss Prevention) suite au blocage de l'action `macie2:EnableMacie`.
    *   *Solution implémentée :* Renforcement de la sécurité préventive par la traçabilité complète des accès (Server Access Logging) et le chiffrement CMK, garantissant la protection des données au repos.

## 🚀 Pipeline CI/CD (Workflow)

Déclenchement automatique à chaque `git push` sur la branche principale :
1.  `actions/checkout@v4` : Récupération du code.
2.  `aws-actions/configure-aws-credentials@v4` : Authentification sécurisée vers AWS.
3.  `bridgecrewio/checkov-action` : Audit de sécurité des fichiers HCL.
4.  `hashicorp/setup-terraform` : Initialisation de l'environnement de déploiement.
5.  `terraform init & apply -auto-approve` : Validation de l'état distant et provisionnement.

## 🛠️ Usage & Reproductibilité

Pour déployer cette infrastructure dans votre propre compte AWS :

```bash
# 1. Configurer le bucket S3 pour le Remote Backend
aws s3 mb s3://<votre-nom-de-bucket-backend> --region eu-north-1

# 2. Mettre à jour le bloc backend dans main.tf avec ce nom de bucket

# 3. Initialiser Terraform (migration vers le Remote Backend)
terraform init

# 4. Vérifier les ressources prévues
terraform plan

# 5. Déployer
terraform apply
