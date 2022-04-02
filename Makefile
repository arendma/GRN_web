install:
	docker build -t grn-web .

run-r:
	docker run -it grn-web R

run-shiny:
	docker run -p 8181:8181 -it grn-web Rscript app.R

test:
	docker run -it grn-web Rscript test.R
