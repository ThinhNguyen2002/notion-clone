FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the build.
# ENV NEXT_TELEMETRY_DISABLED 1

# Set environment variable
ENV CONVEX_DEPLOYMENT=dev:successful-monitor-160
ENV CONVEX_DEPLOY_KEY=prod:combative-lion-525|0126a3e2926ff1ffbca5f3d898bce5669158c1c46c01770fca411126b59b092a284bbc5ac2aa4fa20096ee40079cf77e0b41
ENV NEXT_PUBLIC_CONVEX_URL="https://successful-monitor-160.convex.cloud"
ENV NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_ZW5hYmxpbmctY2l2ZXQtMjIuY2xlcmsuYWNjb3VudHMuZGV2JA
ENV CLERK_SECRET_KEY=sk_test_b90yduEa90GLsjMpPAvtaY94DP7dB8ySMM43l2TqHx
ENV EDGE_STORE_ACCESS_KEY=ThNQ2OGJlZAziRKnVQIadptrawK0l25b
ENV EDGE_STORE_SECRET_KEY=vcxHNf9rbSRhaiYWIPtKD2kZ5Ml9PQZ3uNsdzniRUeMjPx5h

RUN npx convex deploy --cmd "npm run build"
# RUN yarn build

# If using npm comment out above and use below instead
# RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
# Uncomment the following line in case you want to disable telemetry during runtime.
# ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
# set hostname to localhost
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]