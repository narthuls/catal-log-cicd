# 07 — Preuves

Tableau des preuves attendues. À compléter avec vos liens / captures après exécution.

| # | Preuve attendue | Où la trouver | Lien / capture |
|---|---|---|---|
| 1 | Lien du dépôt individuel | `https://github.com/narthuls/catal-log-cicd` | ✅ |
| 2 | Runs GitHub Actions réussis | Onglet **Actions** | _à compléter_ |
| 3 | Build Docker automatisé | Run `01-ci` → étape « Construire l'image » | _à compléter_ |
| 4 | Test HTTP automatisé | Run `01-ci` → étapes « Test HTTP … » | _à compléter_ |
| 5 | Publication GHCR | Page **Packages** du dépôt | _à compléter_ |
| 6 | Tag utilisé | Package GHCR (`latest`, `1.0.0`, `sha-...`) | _à compléter_ |
| 7 | Digest de l'image | Résumé du run `02-publish` (`sha256:...`) | _à compléter_ |
| 8 | Validation recette simulée | Run `03-promote` → job `valider-recette` | _à compléter_ |
| 9 | Promotion sans rebuild | Run `03-promote` → job `promouvoir-production` | _à compléter_ |
| 10 | Extrait / lien du `compose.yml` | Dépôt : `compose.yml` | ✅ |
| 11 | Simulation de scaling et limites | `docs/04-orchestration-c13.md` | ✅ |
| 12 | Test local Docker/Compose | Voir commandes ci-dessous | _à compléter_ |
| 13 | VM personnelle (justification) | `docs/01-cadrage.md` (non nécessaire, justifié) | ✅ |
| 14 | Fiche sécurité | `docs/05-securite.md` | ✅ |
| 15 | Analyse (secrets, rollback, sauvegarde) | `docs/06-analyse-production-reelle.md` | ✅ |
| 16 | Compte rendu final personnel | `docs/08-compte-rendu-final.md` | ✅ |

## Commandes de test local (à exécuter et capturer)

```bash
# Build + run
docker build -t catal-log-site:local .
docker run -d --name catal -p 8080:8080 catal-log-site:local

curl -i http://localhost:8080/            # attendu : 200
curl -s http://localhost:8080/version.json
curl -s http://localhost:8080/healthz     # attendu : ok

# Orchestration légère
docker compose up -d
docker compose ps
docker compose logs --tail=20 monitor

# Simulation scaling
docker compose -f compose.scale.yml up -d --build --scale web=3
docker compose -f compose.scale.yml ps

# Nettoyage
docker rm -f catal
docker compose down
docker compose -f compose.scale.yml down
```

## Comment lire un digest côté GHCR

Dans le résumé du run `02-publish` : ligne **Digest** `sha256:...`.

Le même `sha256:...` sur les tags `latest` et `production` prouve qu'il s'agit du
**même artefact**, promu sans rebuild.
