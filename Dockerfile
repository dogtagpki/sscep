#
# Copyright Red Hat, Inc.
#
# SPDX-License-Identifier: GPL-2.0-or-later
#

################################################################################
FROM registry.fedoraproject.org/fedora:latest AS sscep-builder

# Install build tools
RUN dnf install -y dnf-plugins-core rpm-build

# Import SSCEP source
COPY . /root/sscep/
WORKDIR /root/sscep

# Create source tarball
RUN mkdir -p /root/rpmbuild/SOURCES
RUN tar czvf /root/rpmbuild/SOURCES/sscep-0.10.0-pki.tar.gz \
    --transform "s,^./,sscep-0.10.0-pki/," \
    --exclude .git \
    -C /root/sscep \
    .

# Install build dependencies
RUN dnf builddep -y --spec scripts/sscep.spec

# Build SSCEP packages
RUN rpmbuild -ba scripts/sscep.spec

# Consolidate SSCEP packages
RUN mkdir -p /root/RPMS
RUN find /root/rpmbuild/RPMS -mindepth 2 -type f -exec mv {} /root/RPMS \;

################################################################################
FROM alpine:latest AS sscep-dist

# Import SSCEP packages
COPY --from=sscep-builder /root/RPMS /root/RPMS/

################################################################################
FROM registry.fedoraproject.org/fedora:latest AS sscep

# Import SSCEP packages
COPY --from=sscep-dist /root/RPMS /tmp/RPMS/

# Install SSCEP packages
RUN dnf localinstall -y /tmp/RPMS/* \
    && dnf clean all \
    && rm -rf /var/cache/dnf \
    && rm -rf /tmp/RPMS
