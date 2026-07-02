# 03 — Pipeline CI/CD

Trois workflows composent la chaîne. Chacun a un rôle unique et produit des preuves
visibles dans l'onglet **Actions** de GitHub et dans **GHCR**.

## 01 — CI : build & test

**Déclencheurs** : `push` sur `main`, `pull_request` vers `main`, et manuel.

**Étapes** :

1. Récupération du dépôt.
2. Analyse du `Dockerfile` avec **hadolint** (test complémentaire, non bloquant).
3. Préparation des métadonnées : `version`, `commit` (SHA court), `build_date` (UTC).
4. Construction de l'image avec Buildx (`load: true`, chargée localement).
5. Démarrage du conteneur, attente de l'état `healthy`.
6. **Tests HTTP automatisés** :
   - `GET /` renvoie **200** ;
   - la page contient bien la chaîne `Catal-Log` ;
   - `GET /version.json` est un JSON valide dont `.project == "EC06"` ;
   - `GET /healthz` renvoie `ok`.
7. Journaux du conteneur puis nettoyage.

## 02 — Publish GHCR

**Déclencheurs** : `push` sur `main`, et manuel.

**Permissions** : `packages: write` (publication GHCR via `GITHUB_TOKEN`).

**Étapes** :

1. Préparation des métadonnées + nom d'image en minuscules (contrainte GHCR).
2. Connexion à `ghcr.io` avec `GITHUB_TOKEN` (aucun secret personnel).
3. Build et push avec trois tags : `latest`, version sémantique, `sha-<commit>`.
4. Écriture du **digest** dans le résumé du run (preuve).

**Tag vs digest** :

- **Tag** = référence lisible et mouvante (`latest`, `1.0.0`, `sha-...`).
- **Digest** = empreinte immuable `sha256:...` du manifeste. Deux images au même
  digest sont **strictement identiques**.

## 03 — Promote

**Déclencheur** : **manuel uniquement** (`workflow_dispatch`).

**Job 1 — `valider-recette`** (environnement GitHub `recette`) :

1. `docker pull` de l'image demandée, récupération de son **digest**.
2. Validation par test HTTP sur l'artefact **existant**.

**Job 2 — `promouvoir-production`** (environnement `production-simulee`) :

1. **Re-tag du même digest** via `docker buildx imagetools create`.
2. **Aucune commande `docker build`** : la production reçoit exactement l'artefact validé.
