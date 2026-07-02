# syntax=docker/dockerfile:1
FROM nginxinc/nginx-unprivileged:1.27-alpine

ARG VERSION=0.0.0-local
ARG COMMIT=local
ARG BUILD_DATE=unknown
ARG ENVIRONMENT=recette

LABEL org.opencontainers.image.title="catal-log-site" \
      org.opencontainers.image.description="Site statique Catal-Log servi par Nginx (EC06)" \
      org.opencontainers.image.authors="Noah" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY site/ /usr/share/nginx/html/

RUN echo "{\"project\":\"EC06\",\"application\":\"catal-log-site\",\"author\":\"Noah\",\"formation\":\"ASRC - RNCP39611BC02\",\"version\":\"${VERSION}\",\"environment\":\"${ENVIRONMENT}\",\"commit\":\"${COMMIT}\",\"build_date\":\"${BUILD_DATE}\"}" \
    > /usr/share/nginx/html/version.json

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
