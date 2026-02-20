FROM archlinux:latest

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel sudo git vim nvidia-utils zsh curl cmake openssh

ARG USER_NAME=ataparlar
ARG GIT_EMAIL="ataparlars5@gmail.com"
ARG GIT_NAME="Ata Parlar"

RUN useradd -m -G wheel -s /bin/zsh ${USER_NAME}

RUN echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel

RUN mkdir -p /home/${USER_NAME}/projects /home/${USER_NAME}/data && \
    chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/

ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility,graphics

USER ${USER_NAME}
WORKDIR /home/${USER_NAME}

# Install oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/${USER_NAME}/.oh-my-zsh/custom/themes/powerlevel10k

# Copy the pre-configured .zshrc
COPY --chown=${USER_NAME}:${USER_NAME} .zshrc /home/${USER_NAME}/.zshrc

# Setup SSH key for GitHub
RUN mkdir -p /home/${USER_NAME}/.ssh && \
    ssh-keygen -t ed25519 -C "arch_dev" -N "" -f /home/${USER_NAME}/.ssh/id_ed25519 && \
    ssh-keyscan github.com >> /home/${USER_NAME}/.ssh/known_hosts && \
    git config --global user.email "${GIT_EMAIL}" && \
    git config --global user.name "${GIT_NAME}"

CMD ["/bin/zsh"]