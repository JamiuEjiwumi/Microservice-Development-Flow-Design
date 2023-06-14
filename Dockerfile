FROM node:16-alpine3.16 as builder

RUN  apk --no-cache add curl bash

# RUN apk add --update --no-cache openssl1.1-compat

RUN apk add --no-cache libc6-compat openssl
# install node-prune (https://github.com/tj/node-prune)
RUN curl -sfL https://gobinaries.com/tj/node-prune | bash -s -- -b /usr/local/bin

USER node

WORKDIR /home/node

COPY package.json yarn.lock ./

COPY .env ./

ADD prisma ./prisma

RUN yarn --frozen-lockfile

COPY . /home/node/

RUN yarn prisma:generate

RUN yarn build

# run node prune
RUN /usr/local/bin/node-prune

# remove unused dependencies
RUN rm -rf node_modules/rxjs/src/
RUN rm -rf node_modules/rxjs/bundles/
RUN rm -rf node_modules/rxjs/_esm5/
RUN rm -rf node_modules/rxjs/_esm2015/
RUN rm -rf node_modules/swagger-ui-dist/*.map

# ---

# FROM node:18-alpine
FROM node:16-alpine3.16

USER node
WORKDIR /home/node

COPY --from=builder /home/node/package*.json /home/node/
COPY --from=builder /home/node/yarn.lock /home/node/
COPY --from=builder /home/node/.env /home/node/
COPY --from=builder /home/node/entrypoint.sh /home/node/
COPY --from=builder /home/node/prisma /home/node/prisma
COPY --from=builder /home/node/dist/ /home/node/dist/
COPY --from=builder /home/node/node_modules/ /home/node/node_modules/

EXPOSE 5000

CMD ["/bin/sh", "entrypoint.sh"]
