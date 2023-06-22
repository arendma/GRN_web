install:
	docker build -t grn-web:latest .

run-r:
	docker run -it grn-web:latest R

run-bash:
	docker run -v /tmp/grn-web:/tmp/grn-web -it grn-web:latest bash

run-shiny:
	docker run --env PORT=8181 -p 8181:8181 -it grn-web:latest

run-shiny-prod:
	docker run --name grn-web --env PORT=80 -p 80:80 -d grn-web:latest

test:
	docker run -it grn-web:latest Rscript example.R
