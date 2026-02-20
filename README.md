# Arch-Dev Docker Environment

This repository provides a customizable, containerized development environment running Arch Linux. It comes pre-configured with essential tools such as `zsh`, Oh-My-Zsh (with the Powerlevel10k theme), CMake, and an automated SSH setup for seamless interaction with GitHub securely.

## Quick Start

### 1. Configure Your Setup (Customizing Git and User)

By default, the Docker image is configured to use the following settings:
- `USER_NAME`
- `GIT_EMAIL`
- `GIT_NAME`

**If you are not using the defaults, you MUST override them.** The easiest way to configure these values is by creating a `.env` file in the same directory as the `docker-compose.yml` file:

```env
USER_NAME=yourusername
GIT_EMAIL=your.email@example.com
GIT_NAME=Your Name
```

### 2. Build and Start

Run the following command to build the latest image and launch the container as a background daemon. If you created a `.env` file, Docker Compose will pick it up automatically:

```powershell
docker-compose up -d --build
```

### 3. Connect to GitHub via SSH

As part of the build step, the `Dockerfile` automatically generates a secure `ed25519` SSH key for your user and adds GitHub to the list of known hosts. 

Before you can push or pull securely, you must add the generated public key to your GitHub account:

1. Connect to the container:
   ```powershell
   docker exec -it arch_dev zsh
   ```
2. Retrieve the contents of your new public key:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
3. Copy the entire output string (it should look something like `ssh-ed25519 AAA... arch_dev`).
4. Log into [GitHub](https://github.com/) in your browser.
5. In the top right corner, click your profile photo, then click **Settings**.
6. On the left sidebar, click **SSH and GPG keys**.
7. Click the **New SSH key** button.
8. Add a descriptive title (e.g., "Arch Docker Environment") and paste your copied key into the "Key" box.
9. Click **Add SSH key**.

## Daily Usage

**To enter your development environment:**

```powershell
docker exec -it arch_dev zsh
```

**To cleanly shut down the environment when you are done:**

```powershell
docker-compose down
```
