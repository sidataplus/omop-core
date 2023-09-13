###
# This is workaround solution to extend extra configuration into container builder
#
# Its original appoarch on Broadsea is using volume mount as below example:
# -v ./config-local.js:/tmp/config-local.js:ro -v ./envsubst.sh:/tmp/envsubst.sh:ro
###


FROM ohdsi/atlas:2.13.0

COPY ./src/config-local.js /tmp/config-local.js
COPY ./src/envsubst.sh /tmp/envsubst.sh