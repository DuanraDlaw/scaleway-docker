## -*- docker-image-name: "scaleway/docker" -*-
FROM scaleway/ubuntu:amd64-wily
# following 'FROM' lines are used dynamically thanks do the image-builder
# which dynamically update the Dockerfile if needed.
#FROM scaleway/ubuntu:armhf-wily	# arch=armv7l
#FROM scaleway/ubuntu:arm64-wily	# arch=arm64
#FROM scaleway/ubuntu:i386-wily		# arch=i386
#FROM scaleway/ubuntu:mips-wily		# arch=mips


MAINTAINER Scaleway <opensource@scaleway.com> (@scaleway)


# Prepare rootfs for image-builder
RUN /usr/local/sbin/builder-enter


# Install packages
RUN sed -i '/mirror.scaleway/s/^/#/' /etc/apt/sources.list \
 && apt-get -q update                   \
 && apt-get --force-yes -y -qq upgrade  \
 && apt-get --force-yes install -y -q   \
	apparmor			\
	arping				\
	aufs-tools			\
	btrfs-tools			\
	bridge-utils                    \
	cgroup-lite			\
	git				\
	ifupdown			\
	kmod				\
	lxc				\
	python-setuptools               \
	vlan				\
 && apt-get clean


# Install Docker dependencies
RUN apt-get install $(apt-cache depends docker.io | grep Depends | sed "s/.*ends:\ //" | tr '\n' ' ')


# Install Docker
RUN case "${ARCH}" in                                                                                 \
    armv7l|armhf|arm)                                                                                 \
      echo "docker-hypriot_XXX_armhf.deb built using https://github.com/hypriot/rpi-docker-builder";  \
      wget -q http://downloads.hypriot.com/docker-hypriot_1.10.0-1_armhf.deb -O /tmp/docker.deb &&    \
      dpkg -i /tmp/docker.deb &&                                                                      \
      rm -f /tmp/docker.deb &&                                                                        \
      systemctl enable docker;                                                                        \
      ;;                                                                                              \
    amd64|x86_64|i386)                                                                                \
      curl -L https://get.docker.com/ | sh;                                                           \
      ;;                                                                                              \
    *)                                                                                                \
      echo "Unhandled architecture: ${ARCH}."; exit 1;                                                \
      ;;                                                                                              \
    esac                                                                                              \
 && docker --version


# Install Pipework
RUN wget -qO /usr/local/bin/pipework https://raw.githubusercontent.com/jpetazzo/pipework/master/pipework  \
 && chmod +x /usr/local/bin/pipework


# Install Gosu
ENV GOSU_VERSION=1.7
RUN case "${ARCH}" in                                                                                                \
    armv7l|armhf|arm)                                                                                                \
        wget -qO /usr/local/bin/gosu https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-armhf &&  \
        chmod +x /usr/local/bin/gosu;                                                                                \
      ;;                                                                                                             \
    aarch64|arm64)                                                                                                   \
        wget -qO /usr/local/bin/gosu https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-arm64 &&  \
        chmod +x /usr/local/bin/gosu;                                                                                \
      ;;                                                                                                             \
    x86_64|amd64)                                                                                                    \
        wget -qO /usr/local/bin/gosu https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64 &&  \
        chmod +x /usr/local/bin/gosu;                                                                                \
	;;                                                                                                           \
    *)                                                                                                               \
	echo "Unhandled architecture: ${ARCH}."; exit 1;                                                             \
      ;;                                                                                                             \
    esac                                                                                                             \
 && ( gosu --version || true )
    


# Install Docker Compose
RUN easy_install -U pip                                     \
 && pip install docker-compose                              \
 && ln -s /usr/local/bin/docker-compose /usr/local/bin/fig  \
 && docker-compose --version


# Install Docker Machine
ENV DOCKER_MACHINE_VERSION=0.5.6
RUN case "${ARCH}" in                                                                                                                                        \
    x86_64|amd64|i386)                                                                                                                                       \
        curl -L https://github.com/docker/machine/releases/download/v${DOCKER_MACHINE_VERSION}/docker-machine_linux-amd64 >/usr/local/bin/docker-machine &&  \
        chmod +x /usr/local/bin/docker-machine &&                                                                                                            \
	docker-machine --version;                                                                                                                            \
      ;;                                                                                                                                                     \
    *)                                                                                                                                                       \
	echo "docker-machine not yet supported for this architecture."                                                                                       \
      ;;                                                                                                                                                     \
    esac


# Patch rootfs
COPY ./overlay /
RUN systemctl disable docker; systemctl enable docker


# Clean rootfs from image-builder
RUN /usr/local/sbin/builder-leave
