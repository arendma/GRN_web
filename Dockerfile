FROM bioconductor/bioconductor_docker:RELEASE_3_14

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
