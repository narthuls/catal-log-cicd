# 04 — Orchestration légère et scaling (compétence C13)

Le projet **n'utilise pas Kubernetes** et ne met pas en place d'orchestration de
production réelle. La compétence C13 est traitée via une **orchestration légère
documentée et analysée** avec Docker Compose.

## Rôle de Docker Compose comme orchestration légère

Docker Compose décrit, dans un seul fichier déclaratif, un ensemble de services, leur
réseau, leurs dépendances et leur cycle de vie. Il permet de démarrer, arrêter et
coordonner plusieurs conteneurs d'une commande, de manière reproductible. C'est une
orchestration « légère » : idéale en développement et en démonstration, mais pensée
pour **un seul hôte**.

## Les deux services (`compose.yml`)

| Service | Rôle | Points clés |
|---|---|---|
| `web` | Le site Nginx (l'artefact). | Publie `8080:8080`, `restart: unless-stopped`, `healthcheck`. |
| `monitor` | Sonde de santé. | `depends_on: web` avec `condition: service_healthy`, interroge `/healthz` toutes les 15 s. |

Le service `monitor` démontre la **coordination de plusieurs conteneurs** :

- résolution par **nom de service** (`web`) sur le réseau `catal-log-net` ;
- **ordre de démarrage** contrôlé (`monitor` attend que `web` soit *healthy*) ;
- observation continue, visible via `docker compose logs -f monitor`.

## Simulation de mise à l'échelle

```bash
docker compose -f compose.scale.yml up --build --scale web=3
```

Le fichier `compose.scale.yml` :

1. **ne publie aucun port** sur `web` (seulement `expose: 8080`) ;
2. ajoute un service **`proxy`** (Nginx) publié sur `8080:80`, qui répartit les
   requêtes sur les répliques via le **resolver DNS interne de Docker**.

http://localhost:8080
                        │
                    [ proxy ]  (round-robin via DNS Docker)
                   ┌────┼────┐
                   ▼    ▼    ▼
                web_1 web_2 web_3

## Pourquoi cette simulation ne remplace pas une production

Le `--scale` de Compose crée plusieurs conteneurs **sur une seule machine**. Ce n'est
pas de la haute disponibilité : si l'hôte tombe, tout tombe. Il n'y a ni
rééquilibrage automatique en cas de panne, ni déploiement progressif.

## Limites de Docker Compose

- **Mono-hôte** : pas de répartition sur plusieurs machines.
- **Pas d'auto-réparation** : Compose redémarre un conteneur mort, mais ne reprogramme rien ailleurs.
- **Pas de déploiement progressif** natif (rolling update, canary).
- **Répartition rudimentaire** : le round-robin DNS ne tient pas compte de la charge.

## Comparaison avec Kubernetes

| Critère | Docker Compose (ce projet) | Kubernetes (production réelle) |
|---|---|---|
| Portée | Un seul hôte | Cluster multi-nœuds |
| Mise à l'échelle | `--scale` manuel, mono-hôte | `replicas` + autoscaling (HPA) |
| Haute disponibilité | Non | Oui |
| Auto-réparation | Redémarrage local | Reconciliation permanente |
| Déploiement | Recréation simple | Rolling update, canary, rollback natif |

## Lien avec la robustesse de la chaîne CI/CD

- **Reproductibilité** : la même image se comporte identiquement en CI, en local et en recette.
- **Promotion d'un artefact identifié** : le digest garantit qu'on met à l'échelle exactement ce qui a été testé.
- **Traçabilité** : tags (`sha-...`), digest, labels OCI relient chaque conteneur à un commit précis.
