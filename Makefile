install:
	docker build -t grn-web .

run:
	docker run -it grn-web

test:
	docker run -it grn-web Rscript test.r
