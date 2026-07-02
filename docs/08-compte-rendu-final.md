# 08 — Compte rendu final

## Ce que j'ai réalisé

J'ai mis en place une chaîne CI/CD complète pour publier un petit site statique
Catal-Log servi par Nginx. La chaîne construit une image Docker, la teste
automatiquement, la publie sur GHCR avec un tag et un digest, puis promeut le **même
artefact** vers une production simulée, sans reconstruction.

Le dépôt contient le site (`site/`), une image reproductible (`Dockerfile`), une
orchestration légère à deux services (`compose.yml`), une surcharge de scaling
(`compose.scale.yml`) et trois workflows GitHub Actions (`01-ci`, `02-publish-ghcr`,
`03-promote`).

## Comment fonctionne ma chaîne (dans mes mots)

1. Je pousse une modification sur `main`.
2. `01-ci` construit l'image et lance quatre tests HTTP sur le conteneur (page 200,
   contenu présent, `version.json` cohérent, `/healthz` = ok). Rien n'avance si un
   test échoue.
3. `02-publish-ghcr` reconstruit l'image proprement et la pousse sur GHCR avec les
   tags `latest`, la version et `sha-<commit>`. Le digest est affiché dans le résumé.
4. Quand je décide de livrer, je lance manuellement `03-promote` en indiquant le tag
   à promouvoir. Le workflow valide l'artefact en recette (test HTTP sur l'image
   existante), puis re-tague **le même digest** en `production` — donc **aucun
   rebuild**.

## Points clés que je sais expliquer

- **Tag vs digest** : le tag est une étiquette lisible et mouvante, le digest est
  l'empreinte immuable du contenu. C'est le digest qui prouve que recette et
  production reçoivent exactement la même image.
- **Promotion sans rebuild** : `docker buildx imagetools create` crée un nouveau tag
  pointant sur le manifeste existant, sans reconstruire l'image.
- **Sécurité** : conteneur non-root, base épinglée, en-têtes HTTP durcis, aucun
  secret dans le code, permissions minimales sur les workflows.
- **C13** : Docker Compose comme orchestration légère, un second service `monitor`
  pour la coordination, et une simulation de scaling avec un proxy.

## Difficultés rencontrées et solutions

- Première prise en main de GitHub : création du dépôt et upload des fichiers un par
  un via l'interface web (sans Git installé localement).
- Contrainte de port lors du `--scale` : résolue en retirant la publication de port
  sur `web` et en ajoutant un proxy dans `compose.scale.yml`.
- Nom d'image GHCR à passer en minuscules : géré automatiquement dans le workflow
  avec `tr '[:upper:]' '[:lower:]'`.

## Limites de mon approche

- Environnements recette/production **simulés**, pas d'infrastructure réelle.
- Pas de TLS, pas de scan de vulnérabilités ni de signature d'image.
- Orchestration mono-hôte : pas de haute disponibilité ni d'auto-réparation multi-nœuds.

## Ce que j'ai appris

- La valeur d'un **artefact unique identifié** qui traverse toute la chaîne.
- La distinction concrète entre **CI** (contrôle) et **CD** (publication / promotion).
- Le rôle des **preuves** (runs, tags, digests) dans la traçabilité d'une livraison.

## Pour aller plus loin

Scan d'image (Trivy), signature (cosign), TLS via reverse proxy, supervision
(Prometheus/Grafana ou Zabbix), et à terme Kubernetes pour la haute disponibilité.
