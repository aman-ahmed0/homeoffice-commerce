FROM node:24.21.0-trixie-slim AS build

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:24.21.0-trixie-slim AS dependencies

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM gcr.io/distroless/nodejs24-debian13:nonroot@sha256:bb6b03d81066993293a10feda7250e8e1cc034035fe9b61cfceededa7c8bf04d AS runtime

WORKDIR /app

ENV NODE_ENV=production

COPY --from=dependencies --chown=65532:65532 /app/node_modules ./node_modules
COPY --from=dependencies --chown=65532:65532 /app/package.json ./package.json
COPY --from=build --chown=65532:65532 /app/.next ./.next
COPY --from=build --chown=65532:65532 /app/public ./public
COPY --from=build --chown=65532:65532 /app/next.config.mjs ./next.config.mjs

USER 65532:65532

EXPOSE 3000

CMD ["node_modules/next/dist/bin/next", "start", "-H", "0.0.0.0"]