# Hardening S3 & DevSecOps avec Terraform et Checkov

Projet de déploiement d'une infrastructure cloud sécurisée sur AWS via l'approche "Infrastructure as Code".

##  Objectif
Créer un environnement de stockage S3 respectant les standards de sécurité d'entreprise en intégrant un audit de sécurité automatisé (DevSecOps) avant le déploiement.

## Stack Technique
* **Cloud Provider:** AWS (S3, IAM, KMS)
* **IaC:** Terraform
* **DevSecOps / SCA:** Checkov

## Mesures de sécurité implémentées
1. **Public Access Block:** Interdiction stricte de l'accès public au bucket (CKV2_AWS_6).
2. **Chiffrement au repos:** Forçage de l'algorithme KMS (CKV_AWS_145).
3. **Versioning:** Protection contre les ransomwares ou suppressions accidentelles (CKV_AWS_21).

## Contraintes d'Architecture 

Dans le cadre de ce projet, le compte AWS utilisé est soumis à des **Service Control Policies (SCP)** strictes imposées au niveau de l'organisation (AWS Organizations). 

**1. Blocage OIDC (Zero Trust)**
* **Intention initiale :** Utiliser `aws_iam_openid_connect_provider` pour une authentification GitHub Actions sans mot de passe.
* **Contrainte :** La SCP `p-t0wxvglw` interdit la création de fournisseurs d'identité (Action: `iam:CreateOpenIDConnectProvider`).
* **Fallback implémenté :** Utilisation de GitHub Secrets chiffrés pour stocker les Access Keys, avec un pipeline CI/CD restreint en droits (Least Privilege).

**2. Blocage Amazon Macie (DLP)**
* **Intention initiale :** Activer Macie pour scanner automatiquement les PII (données sensibles) dans le Bucket S3.
* **Contrainte :** La même SCP bloque l'action `macie2:EnableMacie`.
* **Fallback implémenté :** Renforcement de la sécurité préventive via le chiffrement avancé (KMS CMK) et le Server Access Logging pour garantir la traçabilité complète des accès aux données en l'absence d'analyse DLP du contenu.
