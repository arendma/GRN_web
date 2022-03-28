install:
	docker build -t grn-web .

run:
	docker run -it grn-web R

test:
	docker run -it grn-web Rscript test.r
