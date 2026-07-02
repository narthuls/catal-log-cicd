# 06 — Analyse : passage vers une production réelle

## 1. Gestion des secrets

**Pourquoi aucun secret ne doit être dans le code** : un dépôt (même privé) est cloné,
sauvegardé, partagé ; l'historique Git conserve tout. Un secret commité est
considéré comme **compromis définitivement**, même supprimé ensuite.

**Ce qui est déjà en place** : l'authentification GHCR utilise **`GITHUB_TOKEN`**,
généré automatiquement pour chaque run, à portée réduite et détruit en fin de job.
Aucun identifiant n'est écrit dans le dépôt.

**En production réelle**, devraient être placés dans **GitHub Secrets** ou un **coffre
de secrets** (HashiCorp Vault, AWS/GCP/Azure KMS) :

- identifiants d'un registre d'images privé tiers ;
- clés d'accès à l'infrastructure cible (SSH, kubeconfig, tokens cloud) ;
- secrets applicatifs (clés d'API, chaînes de connexion) ;
- certificats et clés privées TLS.

Principes : moindre privilège, rotation régulière, séparation par environnement,
jamais de secret en clair dans les logs.

## 2. Rollback

Le rollback s'appuie sur le fait que **chaque version est un artefact immuable
identifié par son digest**.

- Chaque image publiée porte un tag `sha-<commit>` et un **digest** `sha256:...`.
- Revenir en arrière = **re-promouvoir un artefact déjà construit et déjà validé**,
  sans reconstruction :

```bash
docker buildx imagetools create -t ghcr.io/narthuls/catal-log-site:production \
  ghcr.io/narthuls/catal-log-site:sha-<ancien_commit>
```

- Le workflow `03-promote` accepte en entrée le tag à promouvoir : indiquer un ancien
  `sha-...` réalise un rollback contrôlé.
- Comme on ne rebuild pas, le rollback est **rapide et déterministe**.

## 3. Sauvegarde / restauration

| À sauvegarder | Pourquoi |
|---|---|
| **Dépôt GitHub** (code + historique) | Source de vérité ; permet de tout reconstruire. |
| **Workflows** (`.github/workflows`) | Définition de la chaîne CI/CD. |
| **Documentation** (`docs/`) | Cadrage, sécurité, preuves, procédures. |
| **Images publiées** (GHCR) | Artefacts déployables, identifiés par digest. |
| **Configuration** (Dockerfile, compose, nginx) | Reproduction de l'environnement d'exécution. |
| **Preuves** (runs, captures, tags/digests) | Traçabilité et audit. |
| **Environnements GitHub** | Recette / production, reviewers, visibilité du package. |

**Restauration** : re-cloner le dépôt → re-créer les environnements GitHub →
re-tirer depuis GHCR l'image au digest voulu → re-promouvoir.

## Éléments complémentaires

### a. Séparation stricte des environnements

Recette et production doivent être **réellement isolées** : réseaux, accès et données
distincts. Dans le projet, la séparation est symbolisée par les **environnements
GitHub** et des tags dédiés. En production, on irait plus loin : infrastructures
séparées, secrets par environnement, et une **validation manuelle avant production**
(required reviewer sur l'environnement `production-simulee`).

### b. Supervision et journalisation

Une vraie production nécessite d'**observer** l'état du service : métriques
(disponibilité, latence, taux d'erreur), journaux centralisés et alertes. Le projet
en pose les bases avec la sonde `/healthz`, le `healthcheck` du conteneur et le
service `monitor`. En production, on brancherait une supervision (Prometheus /
Grafana, ou Zabbix/Nagios) et une collecte de logs centralisée.
