FROM openshift/rhel-atomic:latest

ENV NODE_VERSION=${NODE_VERSION:-7.10.1} \
  NEXUS_URL=https://nexus.openshift.devnullcake.com/repository \
  DESCRIPTION="A Node.js (${NODE_VERSION}) container built on top of the \
RHEL Atomic Image. This image provides a node run-time as released."

LABEL summary="Node.js ${NODE_VERSION} container" \
      description="${DESCRIPTION}" \
      io.k8s.description="${DESCRIPTION}" \
      io.k8s.display-name="Node.js ${NODEJS_VERSION}" \
      io.openshift.tags="runtime,nodejs,nodejs-${NODEJS_VERSION},rhel-atomic"

ENV NPM_CONFIG_CAFILE=/etc/ssl/certs/ca-bundle.crt \
  NPM_CONFIG_REGISTRY=${NEXUS_URL}/npm-group

RUN curl -Ls ${NEXUS_URL}/nodejs-release/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz \
      | tar --strip-components 1 -C /usr/local -xz
