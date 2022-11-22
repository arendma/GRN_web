FROM bioconductor/bioconductor_docker:RELEASE_3_14

# set non-root (Heroku requires this)
RUN useradd shiny_user
# make all app files readable, gives rwe permisssion
RUN mkdir /opt/grn-web && chown -R shiny_user:shiny_user /opt/grn-web
RUN chown -R shiny_user:shiny_user /usr/local/lib/R/site-library
USER shiny_user

# We'll copy setup.r and run it before copying all other files,
# so that changing other R files doesn't cause unnecessary reinstalls
# when rebuilding the Docker container.
COPY Program/setup.R /opt/grn-web/Program/
RUN Rscript /opt/grn-web/Program/setup.R

COPY Program/ /opt/grn-web/Program/
COPY Data/ /opt/grn-web/Data/
COPY README.md /opt/grn-web/

WORKDIR /opt/grn-web/Program

# open port used by our shiny app (when run via 'make run-shiny')
EXPOSE 8181
EXPOSE 80

# run app on container start (use heroku port variable for deployment)
CMD ["R", "-e", "shiny::runApp('/opt/grn-web/Program', host = '0.0.0.0', port = as.numeric(Sys.getenv('PORT')))"]

