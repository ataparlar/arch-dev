FROM archlinux:latest

# ── Reliable mirror list ─────────────────────────────────────────────────────
# Replace the default (often slow) mirrors with a curated set of
# CDN-backed and high-bandwidth mirrors to make the build reliable.
RUN echo 'Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch' >  /etc/pacman.d/mirrorlist && \
    echo 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch'        >> /etc/pacman.d/mirrorlist && \
    echo 'Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch'   >> /etc/pacman.d/mirrorlist && \
    echo 'Server = https://mirror.f4st.host/archlinux/$repo/os/$arch'     >> /etc/pacman.d/mirrorlist && \
    # Tune pacman for Docker: parallel downloads, longer timeouts, retries
    sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf && \
    sed -i 's/^#DisableDownloadTimeout/DisableDownloadTimeout/' /etc/pacman.conf

# ── System packages ─────────────────────────────────────────────────────────
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    base-devel sudo git vim nvidia-utils zsh curl wget cmake openssh nano \
    neovim nodejs npm ripgrep fd unzip lazygit \
    clang \
    zstd \
    python python-pipx \
    glibc

ARG USER_NAME=ataparlar
ARG GIT_EMAIL="ataparlars5@gmail.com"
ARG GIT_NAME="Ata Parlar"
# Persist the build ARG as a runtime ENV so it is available after container start
ENV USER_NAME=${USER_NAME}

# ── User setup ───────────────────────────────────────────────────────────────
RUN useradd -m -G wheel -s /bin/zsh ${USER_NAME}
RUN echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel

RUN mkdir -p /home/${USER_NAME}/projects /home/${USER_NAME}/data && \
    chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/

ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility,graphics

# ── Install Ollama (system-wide, as root) ────────────────────────────────────
# Release v0.17+ ships as tar.zst containing bin/ollama + lib/ollama/.
# Extract directly into /usr/local → binary lands at /usr/local/bin/ollama.
RUN curl -fsSL https://github.com/ollama/ollama/releases/latest/download/ollama-linux-amd64.tar.zst \
    | tar -I zstd -xf - -C /usr/local && \
    chmod +x /usr/local/bin/ollama

# ── Switch to user ───────────────────────────────────────────────────────────
USER ${USER_NAME}
WORKDIR /home/${USER_NAME}

# Pre-create the ollama data dir so the named volume inherits correct ownership
# (if created as root first, Ollama cannot write its key files)
RUN mkdir -p /home/${USER_NAME}/.ollama

# ── Python / Aider ───────────────────────────────────────────────────────────
# Arch enforces PEP 668: bare pip and pip --user are both blocked.
# pipx is the Arch-recommended way to install Python CLI applications;
# it creates an isolated venv per app under ~/.local/pipx/.
ENV PATH="/home/${USER_NAME}/.local/bin:${PATH}"
ENV PIPX_HOME="/home/${USER_NAME}/.local/pipx"
ENV PIPX_BIN_DIR="/home/${USER_NAME}/.local/bin"
RUN pipx install aider-install && \
    aider-install

# ── Oh-my-zsh + Powerlevel10k ────────────────────────────────────────────────
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    /home/${USER_NAME}/.oh-my-zsh/custom/themes/powerlevel10k

# Copy the pre-configured .zshrc
COPY --chown=${USER_NAME}:${USER_NAME} .zshrc /home/${USER_NAME}/.zshrc

# ── LazyVim ──────────────────────────────────────────────────────────────────
# Bootstrap LazyVim starter config
RUN git clone https://github.com/LazyVim/starter /home/${USER_NAME}/.config/nvim && \
    rm -rf /home/${USER_NAME}/.config/nvim/.git

# Copy custom plugin specs (clangd LSP, etc.) into LazyVim's plugin directory
COPY --chown=${USER_NAME}:${USER_NAME} nvim-config/lua/plugins/ /home/${USER_NAME}/.config/nvim/lua/plugins/

# ── SSH / Git config ─────────────────────────────────────────────────────────
RUN mkdir -p /home/${USER_NAME}/.ssh && \
    ssh-keygen -t ed25519 -C "arch_dev" -N "" -f /home/${USER_NAME}/.ssh/id_ed25519 && \
    ssh-keyscan github.com >> /home/${USER_NAME}/.ssh/known_hosts && \
    git config --global user.email "${GIT_EMAIL}" && \
    git config --global user.name "${GIT_NAME}"

# ── Entrypoint ───────────────────────────────────────────────────────────────
COPY --chown=${USER_NAME}:${USER_NAME} entrypoint.sh /home/${USER_NAME}/entrypoint.sh
RUN chmod +x /home/${USER_NAME}/entrypoint.sh

CMD ["/bin/zsh", "-c", "/home/${USER_NAME}/entrypoint.sh"]