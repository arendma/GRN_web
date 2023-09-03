# Use Bioconductor as the base image
FROM bioconductor/bioconductor_docker:RELEASE_3_14

# Install Shiny Server
RUN wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.20.1002-amd64.deb && \
    dpkg -i shiny-server-1.5.20.1002-amd64.deb && \
    rm shiny-server-1.5.20.1002-amd64.deb

# Create user for Shiny Server
RUN useradd shiny_user

# Create directory for the Shiny application and set permissions
RUN mkdir /opt/grn-web && chown -R shiny_user:shiny_user /opt/grn-web
RUN chown -R shiny_user:shiny_user /usr/local/lib/R/site-library

# Create directory for logs and set permissions
RUN mkdir -p /var/log/shiny-server && chown -R shiny_user:shiny_user /var/log/shiny-server

# Copy the Shiny Server configuration file into the container
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

# Copy and run the setup script for R packages
COPY Program/setup.R /opt/grn-web/Program/
RUN Rscript /opt/grn-web/Program/setup.R

# Now switch to non-root user for security reasons
USER shiny_user

# Copy the Shiny application into the container
COPY Program/ /opt/grn-web/Program/
COPY Data/ /opt/grn-web/Data/
COPY README.md /opt/grn-web/

# Set working directory
WORKDIR /opt/grn-web/Program

# Expose ports
EXPOSE 8181
EXPOSE 80

# Run Shiny Server
CMD ["/usr/bin/shiny-server"]
