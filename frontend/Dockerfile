FROM node:20-slim AS build

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:20-slim AS runtime

WORKDIR /app

ENV NODE_ENV=production

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY --from=build --chown=node:node /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/next.config.mjs ./next.config.mjs

USER node

EXPOSE 3000

CMD ["npm", "run", "start", "--", "-H", "0.0.0.0"]