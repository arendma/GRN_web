FROM ubuntu:20.04

RUN apt-get update

# Ubuntu 20.04 uses R 3.x, but we want to use R 4.x instead
RUN apt-get -y install software-properties-common && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/' && \
    apt-get update && \
    apt-get install r-base-core -y

# We'll copy setup.r and run it before copying all other files,
# so that changing other R files doesn't cause unnecessary reinstalls
# when rebuilding the Docker container.
COPY Program/setup.R /opt/grn-web/Program/
RUN Rscript /opt/grn-web/Program/setup.R

COPY Program/ /opt/grn-web/Program/
COPY Data/ /opt/grn-web/Data/
COPY README.md /opt/grn-web/

WORKDIR /opt/grn-web/Program

# open port used by our shiny app (defined in app.R)
EXPOSE 8181
