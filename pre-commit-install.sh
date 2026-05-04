#!/bin/bash
set -euo pipefail

# Execute only if git is installed
if ! command -v git >/dev/null 2>&1; then
  echo "git not found; skipping global hooks enforcement"
  exit 0
fi

# Ensure Homebrew is available (Jamf-managed install)
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure pre-commit is available (Jamf-managed install)
if ! command -v pre-commit >/dev/null 2>&1; then
  brew install pre-commit
fi

HOOK_DIR="${HOME}/.githooks"
HOOK_FILE="${HOOK_DIR}/pre-commit"

mkdir -p "${HOOK_DIR}"

cat > "${HOOK_FILE}" <<'EOF'
#!/bin/sh

# Skip if the repo doesn't opt in (no pre-commit config)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "${REPO_ROOT}" ] || [ ! -f "${REPO_ROOT}/.pre-commit-config.yaml" ]; then
    echo "Skipping pre-commit, Missing config file"
    exit 0
fi

if command -v pre-commit >/dev/null 2>&1; then
    echo "Running global pre-commit hooks via pre-commit..."
    exec pre-commit run --hook-stage commit
fi

exit 0
EOF

chmod +x "${HOOK_FILE}"

git config --global core.hooksPath "${HOOK_DIR}"
