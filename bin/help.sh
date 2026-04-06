#!/usr/bin/env bash

set -euo pipefail

cat <<'EOF'
⚡ Shiva

  make help
      📘 Show available project commands
  make update-fivem [FIVEM_NUM=12872|UPDATE_FIVEM_ARGS=--latest]
      🐚 Update the FiveM runtime version via bin/update-fivem.sh
  make submodule-status
      📦 Show current git submodule status
  make submodule-sync
      🔄 Sync and initialize git submodules
  make submodule-links-add
      🔗 Add the default Shiva repo links to .gitmodules
  make submodule-links-remove
      🗑️  Remove the default Shiva repo links from .gitmodules
  make submodule-link-add SUBMODULE_PATH='fivem/resources/[shiva]/shiva-core' SUBMODULE_URL='git@github.com:owner/repo.git'
      ➕ Add a single repo link to .gitmodules
  make submodule-link-remove SUBMODULE_PATH='fivem/resources/[shiva]/shiva-core'
      ➖ Remove a single repo link from .gitmodules
EOF
