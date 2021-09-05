FROM node:10-slim AS edumeet-builder


# Args
ARG BASEDIR=/opt
ARG EDUMEET=edumeet
ARG NODE_ENV=production
ARG SERVER_DEBUG=''
ARG BRANCH=master
ARG REACT_APP_DEBUG=''

WORKDIR ${BASEDIR}

RUN apt-get update;apt-get install -y git bash
ENV NODE\_OPTIONS=--experimental-worker
ENV YARN_IGNORE_NODE=1
RUN yarn set version berry
#checkout code
RUN git clone --single-branch --branch ${BRANCH} https://github.com/kartikey20/edumeet

#install app dep
WORKDIR ${BASEDIR}/${EDUMEET}/app
RUN yarn install
# set app in producion mode/minified/.
ENV NODE_ENV ${NODE_ENV}

# Workaround for the next yarn run build => rm -rf public dir even if it does not exists.
# TODO: Fix it smarter
RUN mkdir -p ${BASEDIR}/${EDUMEET}/server/public

ENV REACT_APP_DEBUG=${REACT_APP_DEBUG}
ENV HTTPS=true
EXPOSE 4443
# package web app
RUN yarn run build

#install server dep
WORKDIR ${BASEDIR}/${EDUMEET}/server

RUN apt-get install -y git build-essential python

RUN yarn install
RUN yarn install logstash-client

FROM node:10-slim

# Args
ARG BASEDIR=/opt
ARG EDUMEET=edumeet
ARG NODE_ENV=production
ARG SERVER_DEBUG=''

WORKDIR ${BASEDIR}


COPY --from=edumeet-builder ${BASEDIR}/${EDUMEET}/server ${BASEDIR}/${EDUMEET}/server



# Web PORTS
EXPOSE 80 443 
EXPOSE 40000-49999/udp


## run server 
ENV DEBUG ${SERVER_DEBUG}

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
