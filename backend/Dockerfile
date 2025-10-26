### Dockerfile for MetartPay backend
# Node 18 base image (matches package.json engines)
FROM node:20-bullseye-slim AS builder

WORKDIR /usr/src/app

# Copy package files first to install deps (leverages caching)
COPY package*.json ./

# Install all dependencies (including dev) for building
RUN npm ci

# Copy source and build
COPY . .

# Build TypeScript by invoking the compiler JS with node (avoids exec permission issues)
RUN node ./node_modules/typescript/bin/tsc --project tsconfig.json

### Final image
FROM node:20-bullseye-slim
WORKDIR /usr/src/app

# Copy package.json and install only production dependencies for smaller image
COPY package*.json ./
RUN npm ci --omit=dev

# Copy built output from builder
COPY --from=builder /usr/src/app/dist ./dist
# Copy runtime config and optional dev helpers (cluster_mints.json, etc.)
COPY --from=builder /usr/src/app/config ./config
## Ensure a dev directory exists in the final image. The builder may not
## always produce a `/usr/src/app/dev` directory (dev helpers are optional),
## so create the directory here to avoid a failing COPY when absent.
RUN mkdir -p ./dev

ENV PORT=8080
EXPOSE 8080

# Start the compiled server
CMD ["node", "dist/index.js"]
