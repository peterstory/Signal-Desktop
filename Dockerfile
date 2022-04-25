FROM ubuntu:20.04

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
  python3 \
  build-essential \
  curl \
  git-lfs \
  libgtk-3-0 \
  libnss3 \
  libdrm2 \
  libgbm1 \
  libasound2
RUN git lfs install

# Electron apps refuse to run as root, so we create the node user
RUN useradd -ms /bin/bash node

# Install the correct version of node
USER node
RUN mkdir -p /home/node/Signal-Desktop
COPY .nvmrc /home/node/Signal-Desktop/.nvmrc
WORKDIR /home/node/Signal-Desktop
SHELL ["/bin/bash", "--login", "-i", "-c"]
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
RUN nvm install `cat .nvmrc`

# Install yarn, a node package manager
RUN npm install --global yarn

# Install dependencies in node_modules
COPY package.json yarn.lock /home/node/Signal-Desktop/
COPY scripts /home/node/Signal-Desktop/scripts/
RUN yarn install --frozen-lockfile

# Configure SUID sandbox helper binary
USER root
RUN chown root:root /home/node/Signal-Desktop/node_modules/electron/dist/chrome-sandbox && \
  chmod 4755 /home/node/Signal-Desktop/node_modules/electron/dist/chrome-sandbox

# TODO
# Integrate the steps below into the Dockerfile after I get yarn test working

RUN apt install -y gdb xvfb
RUN mkdir -p /var/run/dbus
RUN mkdir -p /tmp/.X11-unix && \
  chown root:root /tmp/.X11-unix && \
  chmod 1777 /tmp/.X11-unix
