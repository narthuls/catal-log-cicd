# syntax=docker/dockerfile:1
#
# Image Nginx reproductible servant le site statique Catal-Log.
# Base "unprivileged" : le conteneur tourne en utilisateur non-root (UID 101)
# et écoute sur le port 8080. C'est un choix de sécurité assumé (fiche sécurité).

FROM nginxinc/nginx-unprivileged:1.27-alpine

# --- Métadonnées d'identité du build (renseignées par le workflow) ---
ARG VERSION=0.0.0-local
ARG COMMIT=local
ARG BUILD_DATE=unknown
ARG ENVIRONMENT=recette

# Étiquettes OCI : traçabilité de l'image directement dans son manifeste
LABEL org.opencontainers.image.title="catal-log-site" \
      org.opencontainers.image.description="Site statique Catal-Log servi par Nginx (EC06)" \
      org.opencontainers.image.authors="Noah" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

# Config Nginx durcie (écoute 8080, en-têtes de sécurité, /healthz)
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Contenu du site
COPY site/ /usr/share/nginx/html/

# Injecte l'identité réelle du build dans version.json (écrase la valeur locale)
RUN printf '%s\n' \
    '{' \
    '  "project": "EC06",' \
    '  "application": "catal-log-site",' \
    '  "description": "Site statique Catal-Log servi par Nginx (demonstration CI/CD).",' \
    '  "author": "Noah",' \
    '  "formation": "ASRC - RNCP39611BC02",' \
    "  \"version\": \"${VERSION}\"," \
    "  \"environment\": \"${ENVIRONMENT}\"," \
    "  \"commit\": \"${COMMIT}\"," \
    "  \"build_date\": \"${BUILD_DATE}\"" \
    '}' \
    > /usr/share/nginx/html/version.json

EXPOSE 8080

# Vérifie que Nginx répond ; échoue si le site n'est pas servi
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
