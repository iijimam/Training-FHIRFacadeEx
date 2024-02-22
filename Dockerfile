ARG IMAGE=containers.intersystems.com/intersystems/irishealth-community:2024.1-preview
FROM $IMAGE

USER root

WORKDIR /opt/app
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/app
   
USER ${ISC_PACKAGE_MGRUSER}

COPY  src src
COPY  iris.script .

# run iris and initial 
RUN iris start IRIS \
    && iris session IRIS < iris.script \
    && iris stop IRIS quietly