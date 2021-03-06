# This temporary image is used to produce the build.
FROM node:alpine as build
RUN mkdir -p /home/node/app && chown -R node:node home/node/app

WORKDIR /home/node/app
COPY package*.json ./
USER node
# These have to copy before npm ci because npm ci runs tsc
COPY --chown=node:node . .
RUN npm ci --no-optional
RUN npm run webpack

# This is the final produciton image
FROM node:alpine
# Install tzdata so the timezone can be set correctly in the image via
# the TZ environment variable.
RUN apk --no-cache update && apk --no-cache upgrade && apk --no-cache add tzdata

WORKDIR /home/node/app
USER node
COPY --from=build --chown=node:node /home/node/app/dist/bundle.js ./bundle.js
COPY --from=build --chown=node:node /home/node/app/README.md .
COPY --from=build --chown=node:node /home/node/app/LICENSE .

# Enable polling for watching files by default since it appears that's
# the only way to have file detection work in a Docker container.
# This can always be set to false in docker-compose.yml later if necessary.
ENV CHOKIDAR_USEPOLLING=true

ENTRYPOINT [ "node", "bundle.js" ]