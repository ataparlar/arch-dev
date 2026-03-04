#!/bin/zsh

# ── Fix ~/.ollama ownership ───────────────────────────────────────────────────
# The named volume may have been created by a root-owned process on a previous
# run, leaving the directory (and Ollama's key files) owned by root.
# We own the user, so fix it up before starting the server.
if [ "$(stat -c '%U' "${HOME}/.ollama" 2>/dev/null)" != "${USER}" ]; then
    echo "[entrypoint] Fixing ~/.ollama ownership..."
    sudo chown -R "${USER}:${USER}" "${HOME}/.ollama"
fi

# ── Start Ollama server ───────────────────────────────────────────────────────
ollama serve &
OLLAMA_PID=$!

# ── Wait for Ollama to be ready ───────────────────────────────────────────────
echo "[entrypoint] Waiting for ollama to start..."
until curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; do
    sleep 1
done
echo "[entrypoint] Ollama is ready."

# ── Pull model if not already present ────────────────────────────────────────
if ! ollama list | grep -q "qwen2.5-coder:7b"; then
    echo "[entrypoint] Pulling qwen2.5-coder:7b ..."
    ollama pull qwen2.5-coder:7b
else
    echo "[entrypoint] qwen2.5-coder:7b already present, skipping pull."
fi

# ── Drop into shell ───────────────────────────────────────────────────────────
exec /bin/zsh
