FROM pihole/pihole:latest
ARG TARGETARCH
ARG DEBIAN_FRONTEND="noninteractive"
ARG FTLVER=v5.11

RUN apt-get -y update && apt-get -y upgrade && apt-get -y install unbound unbound-anchor unbound-host dns-root-data wget curl jq openssh-server nano
COPY etc/ /etc/

#USE upstream ugrade method #Define versions en etc/pi-hole-versions 
#RUN rm -R /usr/local/bin/whiptail /usr/local/bin/service /etc/.pihole /var/www/html/admin
#ENV PIHOLE_INSTALL /etc/.pihole/automated\ install/basic-install.sh
#ENV S6_OVERLAY_VERSION v2.1.0.2
#RUN bash -ex install.sh 2>&1 && rm -rf /var/cache/apt/archives /var/lib/apt/lists/*

COPY update-ftl /usr/sbin/
RUN /usr/sbin/update-ftl $TARGETARCH

RUN chown -R root:unbound /etc/unbound && chmod 640 /etc/unbound/unbound.conf.d/* /etc/unbound/zones/*
RUN unbound-anchor -v || unbound-anchor -v


# Configure SSH
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/#\?PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

# Start sshd
CMD ["/entrypoint.sh"]

# Build cmd
# docker buildx build --platform linux/arm64 --load --tag pihole-sshx --progress=plain .