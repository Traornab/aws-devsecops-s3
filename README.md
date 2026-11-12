# Projet DevSecOps AWS : Secure Cloud Storage & CI/CD

![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-S3%20%7C%20KMS%20%7C%20IAM-FF9900?logo=amazonaws&logoColor=white)
![Checkov](https://img.shields.io/badge/Security-Checkov-20B2AA?logo=security)
![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?logo=github-actions&logoColor=white)

## Pourquoi ce projet ?
Étudiant en fin d'études en cybersécurité, j'ai conçu ce projet pour me confronter aux réalités du terrain.

Mon objectif avec ce projet est simple : en apprendre toujours plus sur la sécurité Cloud 
* un domaine qui devient ma passion de jour en jour 
* en construisant de zéro une infrastructure AWS sécurisée, 100 % automatisée avec Terraform et prête pour la production.

J'y ai déployé un coffre-fort numérique (Amazon S3) qui se met à jour tout seul via un pipeline d'intégration continue, avec des contrôles de sécurité à chaque étape.

---

## Mes choix d'architecture
Pour que ce projet soit solide, je me suis basé sur les bonnes pratiques d'AWS :

*   **Stockage Principal (`aws_s3_bucket`) :** J'ai provisionné un bucket S3 privé. J'ai activé le versioning pour être sûr de ne jamais perdre de données, même en cas de suppression accidentelle ou d'attaque ransomware.
*   **Le chiffrement (`aws_kms_key`) :** Je ne voulais pas dépendre de la clé par défaut d'AWS. J'ai donc créé ma propre clé de chiffrement (KMS Customer Managed Key) et j'ai activé sa rotation annuelle automatique.
*   **La traçabilité (`aws_s3_bucket_logging`) :** Pour savoir qui fait quoi. J'ai créé un deuxième bucket S3 qui ne sert qu'à une seule chose : stocker les logs d'accès du premier bucket pour l'analyse forensique.
*   **La mémoire Terraform   :** Pour éviter les conflits quand GitHub déploie mon code, j'ai déporté le fichier d'état (`terraform.tfstate`) dans un "Remote Backend" sur S3.

---

## Sécurité (L'approche DevSecOps)
J'ai intégré la sécurité directement dans mon code et sur l'infrastructure :

1.  **Scan automatique avec Checkov :** À chaque fois que j'envoie du code, Checkov l'analyse. Si je fais une erreur de configuration (par exemple, si j'oublie de chiffrer un disque), le déploiement est immédiatement bloqué.
2.  **Verrouillage du bucket (PAB) :** J'ai activé le blocage strict des accès publics. C'est impossible d'exposer mes données sur internet, même par erreur.
3.  **Moindre privilège :** J'ai configuré les droits de mon robot GitHub Actions pour qu'il n'ait accès qu'au strict minimum.

---

## Les problèmes rencontrés (et mes solutions)
J'ai déployé cette infrastructure sur un compte AWS soumis à des règles d'entreprise très strictes (AWS Organizations avec des SCP). Je me suis pris des erreurs "403 Access Denied", et j'ai dû trouver des plans B sécurisés :

| Ce que je voulais faire | Action IAM bloquée | Le blocage (Contrainte SCP) | Mon plan B (Fallback) |
| :--- | :--- | :--- | :--- |
| **Me connecter sans mot de passe (Authentification Zero Trust OIDC)** | `iam:CreateOpenIDConnectProvider` | Création d'OIDC interdite | J'ai utilisé des clés d'accès classiques, stockées de manière chiffrée dans les *GitHub Secrets*, en limitant fortement les permissions de mon pipeline. |
| **Scanner les données avec l'IA (Data Loss Prevention - Macie)** | `macie2:EnableMacie` | Activation de Macie interdite | Comme je ne pouvais pas faire de scan de données sensibles (PII), j'ai securisé le contenant : chiffrement avancé (**KMS CMK**) obligatoire et journalisation de chaque action sur le bucket (**S3 Access Logs**). |

---

## Mon Pipeline CI/CD
Tout est automatisé. Quand je push mon code sur la branche `main`, GitHub Actions prend le relais :

1.  Il récupère mon code Terraform.
2.  Il s'authentifie sur mon compte AWS.
3.  Il lance l'audit de sécurité (Checkov).
4.  Il prépare l'environnement.
5.  Il déploie l'infrastructure de manière autonome (`terraform apply`).

---

## Tester le projet chez vous
Si vous voulez cloner mon repo et déployer cette architecture sur votre compte AWS :

```bash
# 1. Créez un bucket S3 pour stocker la mémoire Terraform (Backend)
aws s3 mb s3://<votre-nom-de-bucket-backend> --region eu-north-1

# 2. Ajoutez le nom de ce bucket tout en haut du fichier main.tf

# 3. Initialisez le projet
terraform init

# 4. Vérifiez ce qui va être créé
terraform plan

# 5. Déployez !
terraform apply
```

---

## Nettoyage
Exécutez `terraform destroy` et videz manuellement le bucket du Remote Backend à la fin de vos tests pour éviter toute facturation inattendue.
