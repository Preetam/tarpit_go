FROM alpine 

RUN apk add curl jq openjdk8 go wget

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
