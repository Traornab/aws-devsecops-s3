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
