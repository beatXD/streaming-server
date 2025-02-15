# Install dependencies only when needed
FROM node:alpine AS deps
RUN apk add --update --no-cache libc6-compat --virtual builds-deps build-base py-pip
WORKDIR /src/app
COPY package.json ./
COPY tsconfig.json ./
RUN npm install --frozen-lockfile

# Rebuild the source code only when needed
FROM node:alpine AS builder
WORKDIR /src/app
COPY tsconfig.json ./
COPY . .
COPY --from=deps /src/app/node_modules ./node_modules
RUN npm run build

# Production image, copy all the files and run
FROM node:alpine AS runner
WORKDIR /src/app
ENV NODE_ENV production
COPY .env ./
COPY --from=builder /src/app/dist ./dist
COPY --from=builder /src/app/node_modules ./node_modules
COPY --from=builder /src/app/package.json package.json
COPY --from=builder /src/app/tsconfig.json tsconfig.json

EXPOSE 1935 8000 8443

CMD ["npm","start"]