FROM ros:humble-ros-base

ENV DEBIAN_FRONTEND=noninteractive

ARG USERNAME=rr-user
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt-get update \
  && apt-get install -y \
    clang \
    clang-tidy \
    clang-format \
    gdb \
    python3-pip \
    wget \
    vim

RUN pip3 install black

RUN wget https://code.visualstudio.com/sha/download\?build\=stable\&os\=linux-deb-x64 -O code.deb

RUN apt-get install -y ./code.deb

# Setup User
RUN groupadd --gid $USER_GID $USERNAME \
  && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
  && apt-get install -y sudo \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
  && chmod 0440 /etc/sudoers.d/$USERNAME \
  && echo "source /usr/share/bash-completion/completions/git" >> /home/$USERNAME/.bashrc

USER $USERNAME

# Validate setup

RUN mkdir -p /home/$USERNAME/ws/src

WORKDIR /home/$USERNAME/ws

COPY .vscode .vscode
COPY *_extensions.txt .
COPY .env .

# Install extensions
RUN cat general_extensions.txt | xargs -I {} code --install-extension {} \
  && cat cpp_extensions.txt | xargs -I {} code --install-extension {} \
  && cat python_extensions.txt | xargs -I {} code --install-extension {}

# Clean up apt cache
RUN sudo apt-get autoremove -y \
   && sudo apt-get clean -y \
   && sudo rm -rf /var/lib/apt/lists/*
