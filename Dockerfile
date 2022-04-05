# Use base image from https://www.rocker-project.org/
FROM rocker/shiny-verse:4.1.3

# This is needed to avoid "libglpk.so.40: cannot open shared object file",
# cf. https://stackoverflow.com/questions/71609407/unable-to-attach-igraph-or-highcharter-in-rstudio-libglpk-so-40-cannot-open-sh
RUN apt-get update && apt-get install -y libglpk-dev

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
