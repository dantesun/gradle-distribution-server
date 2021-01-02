#!/usr/bin/env bash
docker run --name gradle-distributions -p 8888:80 \
  -v "${PWD}/build/":/usr/share/nginx/html \
  -v "${PWD}/nginx":/etc/nginx \
  nginx
