#!/usr/bin/env bash
# Static contract checks for the oh-my-opencode-slim dotfiles integration.
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

HOME_NIX="$ROOT/home.nix"
OPENCODE_DIR="$ROOT/home/.config/opencode"

require_file() {
  local path=$1 message=$2
  [ -f "$path" ] || fail "$message"
}

json_assert() {
  local path=$1 expression=$2 message=$3
  jq -e "$expression" "$path" >/dev/null || fail "$message"
}

test_home_manager_contract() {
  local home_nix
  home_nix=$(cat "$HOME_NIX")

  assert_contains "$home_nix" '  programs.bun = {' \
    "home.nix does not use the Home Manager Bun module"
  assert_contains "$home_nix" '    enable = true;' \
    "Home Manager Bun module is not enabled"
  assert_contains "$home_nix" 'OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS = "true"' \
    "background subagents are not enabled through Home Manager"
  assert_contains "$home_nix" 'OPENCODE_ENABLE_EXA = "1"' \
    "OpenCode web search is not enabled through Home Manager"

  for path in opencode.jsonc tui.json oh-my-opencode-slim.json; do
    assert_contains "$home_nix" \
      "home.file.\".config/opencode/$path\".source" \
      "home.nix does not manage ~/.config/opencode/$path"
    assert_contains "$home_nix" \
      "\${dotfiles}/home/.config/opencode/$path" \
      "~/.config/opencode/$path does not point into the dotfiles repository"
  done

  pass "Home Manager owns Bun, OpenCode environment variables, and authored config links"
}

test_authored_files_contract() {
  local path
  for path in opencode.jsonc tui.json oh-my-opencode-slim.json; do
    require_file "$OPENCODE_DIR/$path" "authored OpenCode file is missing: $path"
  done

  json_assert "$OPENCODE_DIR/opencode.jsonc" \
    '(.plugin // []) | any(.[]; . == "oh-my-opencode-slim" or startswith("oh-my-opencode-slim@"))' \
    "core OpenCode config does not load oh-my-opencode-slim"
  json_assert "$OPENCODE_DIR/opencode.jsonc" \
    '(.plugin // []) | any(.[]; . == "@dietrichgebert/ponytail" or startswith("@dietrichgebert/ponytail@"))' \
    "core OpenCode config does not load the ponytail plugin"
  json_assert "$OPENCODE_DIR/opencode.jsonc" \
    '.lsp == true' \
    "core OpenCode config does not enable LSP"
  json_assert "$OPENCODE_DIR/opencode.jsonc" \
    '.agent.explore.disable == true and .agent.general.disable == true' \
    "core OpenCode config does not disable the default explore and general agents"
  json_assert "$OPENCODE_DIR/tui.json" \
    '(.plugin // []) | any(.[]; . == "oh-my-opencode-slim" or startswith("oh-my-opencode-slim@"))' \
    "OpenCode TUI config does not load oh-my-opencode-slim"
  json_assert "$OPENCODE_DIR/oh-my-opencode-slim.json" \
    '.preset == "opencode-go"' \
    "oh-my-opencode-slim is not configured for the OpenCode Go preset"
  json_assert "$OPENCODE_DIR/oh-my-opencode-slim.json" \
    '.multiplexer.type == "herdr"' \
    "oh-my-opencode-slim is not configured to use Herdr"
  json_assert "$OPENCODE_DIR/oh-my-opencode-slim.json" \
    '(.companion.enabled // false) == false' \
    "oh-my-opencode-slim Companion is enabled"

  if rg -n -i '"(apiKey|api_key|accessToken|access_token|secret|password)"' \
    "$OPENCODE_DIR" >/dev/null 2>&1; then
    fail "authored OpenCode files contain a credential-like key"
  fi

  pass "authored OpenCode files contain the approved provider, Herdr, and safety settings"
}

test_home_manager_contract
test_authored_files_contract
