install:
	docker build -t grn-web .

run-r:
	docker run -it grn-web R

run-bash:
	docker run -v /tmp/grn-web:/tmp/grn-web -it grn-web bash

run-shiny:
	docker run --env PORT=8181 -p 8181:8181 -it grn-web

run-shiny-prod:
	docker run --restart=always --env PORT=80 -p 80:80 -it grn-web

test:
	docker run -it grn-web Rscript Program/example.R
	docker run -it grn-web Rscript run_tests.R
