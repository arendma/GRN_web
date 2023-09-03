install:
	docker build -t grn-web:latest .

run-r:
	docker run -it grn-web:latest R

run-bash:
	docker run -v /tmp/grn-web:/tmp/grn-web -it grn-web:latest bash

run-shiny:
	mkdir -p ~/shiny-logs
	docker run -v ~/shiny-logs:/var/log/shiny-server --env PORT=8181 -p 8181:3838 -it grn-web:latest

run-shiny-prod:
	mkdir -p ~/shiny-logs
	docker run -v ~/shiny-logs:/var/log/shiny-server --name grn-web --env PORT=80 -p 80:3838 -d grn-web:latest

test:
	docker run -it grn-web:latest Rscript example.R
