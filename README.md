# GRN_web

This repository contains the code for accessing the consensus and PHOT network from the publication ["Widening the landscape of transcriptional regulation of algal photoprotection"](https://www.biorxiv.org/content/10.1101/2022.02.25.482034v3).
via a web interface. The webinterface can be reached at [http://grn-web.bio.uni-potsdam.de/](http://grn-web.bio.uni-potsdam.de/)

You can use the code in this repository to run a local version of the web-interface following the setup instructions below.

## Setup

You have two options:

### Direct Installation

- install R (version 4.0 or higher) [according to your OS installation instructions](https://cran.r-project.org/)
- clone this repository
- change into the `./Program` directory of this repo and run `Rscript setup.R`

### Docker-based Installation

This is mainly useful if you just want to run the GRN_web interface or
if you need to keep your existing R installation untouched.

- install Docker [according to your OS installation instructions](https://docs.docker.com/engine/install/)
- clone this repository
- inside the repository's main directory, run `docker build -t grn-web .` to install GRN_web inside a Docker container
- afterwards, you can start the container like this: `docker run --env PORT=8181 -p 8181:8181 -it grn-web`
- now, visit http://localhost:8181/ in your browser to use GRN_web


## Usage example

To use the web interface, change into the `./Program` directory and execute `Rscript app.R`.
It will show the URL you need to use in your browser, e.g. `http://127.0.0.1:3395`.
This is how the app looks like:

![GRN_web demo screencast](grn-web-demo.gif)


