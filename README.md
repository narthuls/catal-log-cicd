# Catal-Log — Chaîne CI/CD (EC06)

Pipeline CI/CD simple, lisible et traçable pour publier un petit site web statique
servi par Nginx. Le projet couvre la **construction**, le **test**, la **publication**
et la **promotion** d'une image Docker, via **GitHub Actions** et **GitHub Container
Registry (GHCR)**, avec simulation des environnements *recette* et *production*.

> Formation ASRC · Évaluation **EC06** · Auteur : 09

## Principe

La même image Docker traverse toute la chaîne, du commit à la production. Elle n'est
**jamais reconstruite** entre la recette et la production : c'est le même artefact,
identifié par son **tag** et son **digest**.

## Arborescence
.

├── site/

│   ├── index.html

│   ├── version.json

│   └── assets/styles.css

├── nginx/

│   ├── default.conf

│   └── proxy.conf

├── Dockerfile

├── compose.yml

├── compose.scale.yml

├── .github/workflows/

│   ├── 01-ci.yml

│   ├── 02-publish-ghcr.yml

│   └── 03-promote.yml

└── docs/

## Démarrage rapide (local)

```bash
docker build -t catal-log-site:local .
docker run -d -p 8080:8080 catal-log-site:local
curl http://localhost:8080/
curl http://localhost:8080/version.json
docker compose up -d
docker compose -f compose.scale.yml up --build --scale web=3
```

## Documentation

Toute la documentation est dans [`docs/`](docs/).
