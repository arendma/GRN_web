#!/bin/bash
docker stop grn-web
docker rm grn-web
docker run --name grn-web --env PORT=80 -p 80:80 -d grn-web:latest
