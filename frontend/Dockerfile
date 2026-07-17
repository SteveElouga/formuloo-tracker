# syntax=docker/dockerfile:1
# Frontend Angular — build multi-stage, servi par nginx non-root (port 8080). FT-1.
FROM node:20-bookworm-slim AS builder
WORKDIR /app
RUN corepack enable
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile || pnpm install
COPY . .
RUN pnpm run build

FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist/browser /usr/share/nginx/html
EXPOSE 8080
