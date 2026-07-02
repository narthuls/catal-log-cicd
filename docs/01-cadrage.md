# 01 — Cadrage du projet

## Contexte

Catal-Log souhaite industrialiser la publication d'un petit site web statique afin
d'éviter les opérations manuelles répétitives, de fiabiliser les livraisons et de
conserver des preuves d'exécution. Le rôle confié est de mettre en place une chaîne
CI/CD **simple, lisible et traçable**.

- **Formation** : Administrateur Systèmes, Réseaux et Cybersécurité — RNCP39611
- **Bloc** : RNCP39611BC02 — Configurer et administrer l'infrastructure réseau et les solutions cloud
- **Évaluation** : EC06 — Automatisation d'intégration et de déploiement continu
- **Livrable principal** : pipeline CI/CD fonctionnel avec conteneurisation et pratiques de sécurité DevOps

## Mission

Construire, tester, publier et promouvoir une image Docker Nginx contenant un site
statique simple, via GitHub Actions et GitHub Container Registry, avec simulation des
environnements recette et production dans GitHub :

1. versionner une modification dans un dépôt GitHub individuel ;
2. contrôler automatiquement le projet à chaque push ;
3. construire une image Docker à partir d'un `Dockerfile` ;
4. tester automatiquement le conteneur dans GitHub Actions ;
5. publier l'image dans GHCR ;
6. identifier l'image par un **tag** et un **digest** ;
7. valider l'image en recette simulée ;
8. promouvoir manuellement **le même artefact** vers une production simulée, **sans rebuild** ;
9. documenter les choix, les limites et les preuves vérifiables.

## Périmètre

| Dans le périmètre | Hors périmètre |
|---|---|
| Site statique servi par Nginx | Backend applicatif, base de données |
| Image Docker reproductible | Orchestration de production réelle (Kubernetes) |
| CI (build + tests HTTP) | Tests de charge / performance |
| Publication GHCR (tag + digest) | Signature d'image / SBOM (mentionnés en piste) |
| Promotion recette → production **simulées** | Déploiement sur une vraie infrastructure |

## Choix techniques et justifications

| Choix | Justification |
|---|---|
| **Nginx (image non-root)** | Serveur statique léger et éprouvé. La variante *unprivileged* fait tourner le conteneur en utilisateur non-root (UID 101, port 8080) : moindre surface d'attaque. |
| **Base image épinglée** (`1.27-alpine`) | Reproductibilité : une version figée évite qu'un `latest` fasse dériver le build dans le temps. |
| **Injection de version au build** (build args) | `version.json` porte l'identité réelle du build sans dépendre d'un service externe. |
| **GitHub Actions + GHCR** | Runners éphémères sans serveur à administrer ; registre intégré à GitHub, authentification par `GITHUB_TOKEN`. |
| **Promotion par re-tag du digest** (`imagetools`) | Garantit que la production reçoit **exactement** l'artefact validé en recette, sans reconstruction. |

## Test local et VM personnelle

- **Test local Docker/Compose** : réalisé (voir `docs/07-preuves.md`).
- **VM personnelle** : non nécessaire — les runners GitHub-hosted fournissent
  l'environnement d'exécution éphémère (justification de non-utilisation).
