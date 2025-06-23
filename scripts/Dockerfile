FROM debian:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV REPO_URL=""

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y git sudo make

# Create workspace
WORKDIR /root/workspace

# Clone the repo and run commands
RUN if [ ! -z "$REPO_URL" ]; then \
        git clone "$REPO_URL"; \
    fi

# Set working directory and run build steps
WORKDIR /root/workspace/debian-live-config

RUN make install_buildenv && make

CMD [ "bash" ]
