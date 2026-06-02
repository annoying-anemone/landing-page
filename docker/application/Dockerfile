FROM node:26.3-bookworm-slim AS base

ENV DEBIAN_FRONTEND=noninteractive
# hadolint ignore=DL3008,DL3016
RUN \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eu; \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    curl ca-certificates

# hadolint ignore=DL3016
RUN --mount=type=cache,target=/root/.npm \
    set -eu; \
    npm install -g npm;

USER node
WORKDIR /usr/src/app

FROM base AS build

USER root
ENV DEBIAN_FRONTEND=noninteractive
# hadolint ignore=DL3008,DL3016
RUN \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eu; \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    dumb-init
USER node

ARG APP_PATH=
COPY --chown=node:node $APP_PATH/package*.json /usr/src/app/

RUN --mount=type=secret,mode=0644,id=npmrc,target=/usr/src/app/.npmrc \
    --mount=type=cache,target=/root/.npm \
    set -eu; \
    npm ci --force;

COPY --chown=node:node $APP_PATH/ /usr/src/app/

FROM build AS build-app

USER node
RUN \
    --mount=type=cache,target=/usr/src/app/node_modules/.astro,uid=1000,gid=1000 \
    set -eu; \
    npm run build;

RUN set -eu; \
    npm prune --production

FROM nginx:1.31-alpine AS prod

COPY docker/application/conf/nginx.conf /etc/nginx/nginx.conf

COPY --from=build-app /usr/src/app/dist/ /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 CMD curl -f http://localhost:8080 || exit 1

FROM build AS ci

CMD [ "tail", "-f", "/dev/null" ]

FROM base AS dev

CMD [ "tail", "-f", "/dev/null" ]

EXPOSE 8080