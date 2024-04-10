# syntax=docker/dockerfile:1

FROM scratch

LABEL maintainer="Tanc"

# copy local files
COPY root/ /
