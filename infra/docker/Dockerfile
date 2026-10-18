FROM node:24-bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends openssl ca-certificates && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@10.11.0 --activate
WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/server/package.json apps/server/package.json
COPY apps/realtime/package.json apps/realtime/package.json
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm db:generate && pnpm build
ENV NODE_ENV=production
USER node
EXPOSE 3000 3001
CMD ["pnpm","--filter","@qchat/server","start"]
