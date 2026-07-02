# 05 — Fiche sécurité

## Mesures appliquées dans le projet

| Domaine | Mesure | Où |
|---|---|---|
| **Conteneur non-root** | Image `nginx-unprivileged` : exécution en UID 101, écoute sur 8080. Réduit l'impact d'une compromission. | `Dockerfile` |
| **Base image épinglée** | `1.27-alpine` (pas de `latest`) : build reproductible, pas de dérive silencieuse. | `Dockerfile` |
| **Surface minimale** | Base Alpine (petite image), `.dockerignore` exclut docs, `.git`, workflows du contexte de build. | `.dockerignore` |
| **En-têtes HTTP de sécurité** | `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, `server_tokens off`. | `nginx/default.conf` |
| **Pas de secret dans le code** | Aucune clé ni mot de passe dans le dépôt. Authentification GHCR via `GITHUB_TOKEN` éphémère. | workflows |
| **Permissions minimales** | Workflows en `contents: read` ; `packages: write` uniquement là où c'est nécessaire. | `02`, `03` |
| **Healthcheck** | Sonde `/healthz` : détecte un conteneur non fonctionnel. | `Dockerfile`, `nginx/default.conf` |
| **Traçabilité** | Labels OCI (`version`, `revision`, `created`), tag `sha-...`, digest. | `Dockerfile`, `02-publish` |
| **Analyse statique** | `hadolint` sur le `Dockerfile` en CI. | `01-ci.yml` |

## Gestion des secrets

- Aucun secret n'est stocké dans le code ni dans les images.
- Le seul « secret » utilisé est **`GITHUB_TOKEN`**, injecté automatiquement par
  GitHub à chaque run, à portée limitée et à durée de vie du job.
- Tout secret futur devrait passer par **GitHub Secrets** ou un **coffre de secrets**
  (Vault, cloud KMS).

## Risques couverts / non couverts

| Risque | Statut | Commentaire |
|---|---|---|
| MIME-sniffing | Couvert | `nosniff` |
| Clickjacking | Couvert | `X-Frame-Options: DENY` |
| Fuite de version serveur | Couvert | `server_tokens off` |
| Exécution root dans le conteneur | Couvert | image non-root |
| Fuite de secret dans le code | Couvert | aucun secret versionné |
| Vulnérabilités des dépendances | **Non couvert** | pas de scan d'image (piste ci-dessous) |
| Chiffrement TLS | **Non couvert** | HTTP simple ; un vrai déploiement placerait un reverse proxy TLS devant |

## Pistes d'amélioration (production)

- **Scan de vulnérabilités** de l'image (Trivy / Grype) en CI.
- **Signature d'image** (cosign) et **SBOM** pour la provenance.
- **TLS** via un reverse proxy et certificats gérés.
- **Dependabot** pour suivre les mises à jour de la base image et des actions.
