# 02 — Architecture

## Vue d'ensemble
Développeur

│  git push

▼

┌──────────────┐     ┌───────────────────────────── GitHub Actions ─────────────────────────────┐

│ Dépôt GitHub │────▶│  01-ci                02-publish-ghcr            03-promote                │

│  (main)      │     │  build image          build + push        pull digest ─▶ re-tag digest    │

└──────────────┘     │  tests HTTP ──si OK──▶ tag + digest ──┐         (recette) (production sim.)│

└───────────────────────────────────────┼──────────────────────────────────┘

▼

┌──────────────────┐

│       GHCR       │

│  image + tags +  │

│      digest      │

└──────────────────┘

│            ▲

pull + valider│            │source du re-tag

▼            │

[ recette ]  ──────▶ [ production simulée ]

validation      promotion sans rebuild

## Composants

| Composant | Rôle |
|---|---|
| **Dépôt GitHub** | Code, historique de commits, workflows, documentation et preuves. |
| **GitHub Actions** | Contrôles, build Docker, tests, publication GHCR, promotion. |
| **Runners GitHub-hosted** | Environnements d'exécution temporaires, sans serveur à administrer. |
| **Dockerfile** | Construction reproductible de l'image Nginx contenant le site. |
| **GHCR** | Publication de l'image et conservation des tags / digests. |
| **compose.yml** | Orchestration légère (service web + service monitor). |
| **Environnements GitHub** | `recette` et `production-simulee`, simulés dans GitHub. |

## Architecture applicative (dans l'image)
┌──────────────── conteneur (UID 101, non-root) ────────────────┐

│  Nginx (écoute :8080)                                          │

│    ├── /                → /usr/share/nginx/html/index.html     │

│    ├── /assets/styles.css                                      │

│    ├── /version.json    (Cache-Control: no-store)              │

│    └── /healthz         (200 "ok")  ◀── HEALTHCHECK + test CI  │

│  En-têtes : X-Content-Type-Options, X-Frame-Options, ...       │

└───────────────────────────────────────────────────────────────┘
## Flux de données (identité du build)

1. `site/version.json` contient une identité locale (valeurs `local`).
2. À la construction, le `Dockerfile` **réécrit** `version.json` avec les vraies
   valeurs passées en *build args* (version, commit court, date UTC, environnement).
3. Le site charge `/version.json` côté navigateur et affiche l'identité du build
   déployé (version, environnement, commit, date).
