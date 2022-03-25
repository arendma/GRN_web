FROM ubuntu:20.04

# some package depends on tzdata, so we need this workaround:
# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get update && \
    apt-get upgrade -y && \
    apt-get -y install tzdata

RUN apt-get install r-base-core -y

# We'll copy setup.r and run it before copying all other files,
# so that changing other R files doesn't cause unnecessary reinstalls
COPY Program/setup.r /opt/grn-web/Program/
RUN Rscript /opt/grn-web/Program/setup.r

COPY Program/ /opt/grn-web/Program/
COPY Data/ /opt/grn-web/Data/
COPY README.md /opt/grn-web/

WORKDIR /opt/grn-web/Program
