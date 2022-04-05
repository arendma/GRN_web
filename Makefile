install:
	docker build -t grn-web .
run-r:
	docker run -it grn-web R

run-bash:
	docker run -it grn-web bash

run-shiny:
	docker run --env PORT=8181 -p 8181:8181 -it grn-web

test:
	docker run -it grn-web Rscript test.R
