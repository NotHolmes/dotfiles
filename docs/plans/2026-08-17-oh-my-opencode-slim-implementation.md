# oh-my-opencode-slim Dotfiles Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Install and configure `oh-my-opencode-slim` for the OpenAI provider through the dotfiles repository, with authored configuration reproducibly managed by Home Manager and runtime-generated files left unmanaged.

**Architecture:** Keep `home.nix` as the source of truth for Bun, OpenCode environment variables, and links to authored OpenCode configuration. Use the upstream latest installer once to generate the current OpenCode/plugin configuration, adopt only the authored JSON files into `home/.config/opencode`, and let the installer and Herdr manage generated runtime artifacts. Companion remains disabled. Herdr is selected through the tracked plugin configuration.

**Tech Stack:** Nix Home Manager, nix-darwin, Homebrew OpenCode, Bun, `oh-my-opencode-slim@latest`, Herdr, shell tests, `jq`.

---

## Task 1: Add a focused configuration test before implementation

**Files:**
- Create: `tests/opencode.test.sh`

**Steps:**

1. Add a shell test using `set -euo pipefail` and repository-relative paths. Test the intended static contract:
   - `home.nix` includes `bun` in `home.packages`.
   - `home.sessionVariables` includes `OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS = "true"` and `OPENCODE_ENABLE_EXA = "1"`.
   - `home.nix` links `opencode.jsonc`, `tui.json`, and `oh-my-opencode-slim.json` from the repository.
   - The three authored files exist under `home/.config/opencode`.
   - The core config contains the `oh-my-opencode-slim` plugin, enables LSP, and disables the default `explore` and `general` agents.
   - The TUI config contains the plugin entry.
   - The plugin config uses the `openai` preset, selects the `herdr` multiplexer, and has Companion disabled or absent.
   - No obvious credential keys or values are present in the authored files.
2. Use `jq` for JSON assertions and simple text assertions for Nix expressions. Keep assertions descriptive so a failed check points to the violated contract.
3. Run `bash tests/opencode.test.sh` and confirm it fails because the implementation has not been added yet.

## Task 2: Add Bun and OpenCode environment configuration to Home Manager

**Files:**
- Modify: `home/home.nix`

**Steps:**

1. Enable Home Manager's Bun module:

   ```nix
   programs.bun = {
     enable = true;
   };
   ```

2. Replace the single `home.sessionVariables.EDITOR` assignment with a `home.sessionVariables` attribute set containing:

   ```nix
   EDITOR = "nvim";
   OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS = "true";
   OPENCODE_ENABLE_EXA = "1";
   ```

3. Preserve the existing package ordering and unrelated configuration.
4. Run `./rebuild.sh` from the dotfiles repository so Bun and the environment configuration are applied before invoking the upstream installer.
5. Open a new login shell after the rebuild and confirm `bun --version` works and both `OPENCODE_*` variables are present.

## Task 3: Generate the upstream OpenCode configuration using the approved choices

**Files:**
- Generated temporarily under: `~/.config/opencode`

**Steps:**

1. Inspect the current OpenCode files and preserve the existing schema-only `opencode.jsonc` before running the installer.
2. Run the upstream installer with latest versions and the approved non-interactive choices:

   ```sh
   bunx oh-my-opencode-slim@latest install \
     --no-tui \
     --skills=yes \
     --preset=openai \
     --background-subagents=no \
     --companion=no
   ```

3. Confirm the installer adds the plugin and TUI entries, generates the OpenAI preset configuration, disables the default `explore` and `general` agents, enables LSP, and syncs the bundled skills.
4. Keep background-subagent shell setup disabled because the approved configuration manages the environment variables through Home Manager instead.
5. Do not copy `node_modules`, `package.json`, `bun.lock`, caches, or generated Herdr files into the dotfiles repository.

## Task 4: Adopt and complete the authored OpenCode configuration

**Files:**
- Create or update: `home/.config/opencode/opencode.jsonc`
- Create or update: `home/.config/opencode/tui.json`
- Create or update: `home/.config/opencode/oh-my-opencode-slim.json`

**Steps:**

1. Copy the generated authored JSON files from `~/.config/opencode` into the repository, retaining the current JSON/JSONC formats and the installer-generated current model mappings.
2. Add the approved Herdr setting to the plugin config:

   ```json
   "multiplexer": {
     "type": "herdr"
   }
   ```

3. Keep Companion disabled and do not add credentials or provider API keys.
4. Validate all three files with `jq` where applicable. For JSONC, use the repository's existing format and validate the JSON-compatible content after accounting for comments if present.
5. Review the diff to ensure only the intended generated configuration and the Herdr setting are present.

## Task 5: Manage authored OpenCode files through Home Manager

**Files:**
- Modify: `home/home.nix`

**Steps:**

1. Add `home.file` entries using `config.lib.file.mkOutOfStoreSymlink` for:
   - `.config/opencode/opencode.jsonc`
   - `.config/opencode/tui.json`
   - `.config/opencode/oh-my-opencode-slim.json`
2. Leave `AGENTS.md`, `package.json`, `bun.lock`, `node_modules`, plugin caches, generated skills, and Herdr integration files under their existing ownership.
3. Before applying the links, verify the generated files have already been adopted into the repository so Home Manager does not overwrite an unreviewed regular file.
4. Run `./rebuild.sh` and confirm the three live authored files are symlinks into the dotfiles repository.

## Task 6: Install the one-time Herdr OpenCode integration and document the workflow

**Files:**
- Modify: `README.md`

**Steps:**

1. Run the one-time generated integration command:

   ```sh
   herdr integration install opencode
   ```

2. Confirm `herdr integration status` reports the OpenCode integration as current.
3. Add a concise OpenCode section to the README documenting:
   - `./rebuild.sh` manages Bun, environment variables, and authored OpenCode links.
   - `herdr integration install opencode` is a one-time machine-local setup command.
   - `opencode auth login` and `opencode models --refresh` are account/runtime actions, not secret-bearing dotfiles.
   - To use Herdr panes, start `herdr`, then run `opencode --port 4096` inside it.
   - Companion is intentionally disabled.
   - The plugin and bundled skills track upstream latest versions at install/update time.
4. Do not document or copy generated runtime files as repository-managed configuration.

## Task 7: Verify the complete setup and record manual follow-up

**Files:**
- No additional files expected.

**Steps:**

1. Run the focused test:

   ```sh
   bash tests/opencode.test.sh
   ```

2. Run repository checks appropriate to the changed Nix and shell files:

   ```sh
   nix flake check --no-build
   nix build .#darwinConfigurations.mac.system --dry-run
   git diff --check
   ```

3. Run runtime checks:

   ```sh
   bunx oh-my-opencode-slim@latest doctor
   opencode --version
   herdr integration status
   ```

4. Confirm the live authored files point into the dotfiles checkout and the new login shell exposes both OpenCode environment variables.
5. Run any relevant existing repository tests and fix failures caused by this change. Do not alter unrelated untracked files, especially `home/.config/herdr/.plugins.lock`.
6. Report the remaining interactive account actions for the user to perform:
   - `opencode auth login`
   - `opencode models --refresh` after authentication
   - start OpenCode inside Herdr when pane orchestration is desired
   - run the upstream `ping all agents` smoke check after authentication
7. Leave all changes, including this plan, uncommitted for the user to review and commit.
