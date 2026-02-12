FROM archlinux:latest

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel sudo git vim nvidia-utils zsh

RUN useradd -m -G wheel -s /bin/zsh ataparlar

RUN echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel

RUN mkdir -p /home/ataparlar/projects /home/ataparlar/data && \
    chown -R ataparlar:ataparlar /home/ataparlar/

ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility,graphics

USER ataparlar
WORKDIR /home/ataparlar

CMD ["/bin/bash"]