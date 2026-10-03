# oh-my-opencode-slim integration design

Date: 2026-08-17

## Goal

Install and configure `oh-my-opencode-slim` for the existing Home Manager and nix-darwin dotfiles setup while keeping authored configuration reproducible and runtime state unmanaged.

The plugin and its internal tools may track upstream latest versions. Reproducibility means the repository owns the setup structure, configuration, environment, and provisioning instructions.

## Decisions

- The source of truth is `/Users/holmes/Repositories/dotfiles`, exposed as `~/.dotfiles`.
- OpenAI is the active generated model preset.
- Bun is installed from `nixpkgs` through Home Manager.
- Background subagents and built-in web search are enabled through Home Manager session variables:
  - `OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true`
  - `OPENCODE_ENABLE_EXA=1`
- Herdr is the selected multiplexer with a `main-vertical` layout.
- Upstream bundled skills are enabled.
- The optional Companion desktop window stays disabled.
- The upstream installer uses its latest-tracking plugin entry and remains responsible for latest plugin and bundled-skill runtime updates.

## Ownership model

Home Manager will symlink only authored files from the repository:

- `home/.config/opencode/opencode.jsonc`
- `home/.config/opencode/tui.json`
- `home/.config/opencode/oh-my-opencode-slim.json`

The following remain unmanaged runtime state under `~/.config/opencode`:

- `node_modules`, `package.json`, and `bun.lock`
- OpenCode and plugin caches
- Bundled skill files and update staging files
- Installer backup files
- The generated Herdr integration file, which is owned by Herdr

This avoids symlinking the entire OpenCode directory and preserves the existing runtime package setup.

## Installation flow

1. Add Bun and the two OpenCode environment variables to `home.nix`.
2. Apply Home Manager with `./rebuild.sh`.
3. Run the upstream installer with explicit non-interactive choices:

   ```sh
   bunx oh-my-opencode-slim@latest install \
     --no-tui \
     --skills=yes \
     --preset=openai \
     --background-subagents=no \
     --companion=no
   ```

   The shell setup flag is disabled because Home Manager owns the environment. The installer still adds the plugin and TUI entries, configures OpenCode defaults, generates the plugin configuration, warms the plugin cache, and synchronizes bundled skills.

4. Adopt the installer-generated authored configuration into `home/.config/opencode` without losing the existing OpenCode schema setting.
5. Add the Herdr multiplexer setting to the tracked plugin configuration.
6. Add individual Home Manager symlinks for the three authored OpenCode files.
7. Run `herdr integration install opencode` once to install Herdr's generated OpenCode lifecycle integration.
8. Document authentication, model refresh, Herdr launch, and verification commands in the dotfiles README.

## Runtime behavior

OpenCode loads the plugin from the tracked core configuration. The plugin loads the tracked agent preset and Herdr settings, while its latest package and bundled skills remain in runtime-managed locations. Existing OpenCode sessions must be restarted after configuration or environment changes.

Authentication remains user-owned and interactive:

```sh
opencode auth login
opencode models --refresh
```

For visible specialist panes, OpenCode must be started inside Herdr, for example:

```sh
herdr
opencode --port 4096
```

## Safety and compatibility

- Preserve the existing unrelated untracked file `home/.config/herdr/.plugins.lock`.
- Do not symlink over the OpenCode runtime directory.
- Do not overwrite an existing plugin configuration without a backup and diff review.
- Do not add credentials or provider secrets to the repository.
- Do not enable Companion or introduce additional providers.
- Keep the Herdr generated integration outside the repository because Herdr explicitly owns and may overwrite it.

## Verification

Run repository and configuration checks after implementation:

- `nix flake check --no-build`
- `nix build .#darwinConfigurations.mac.system --dry-run`
- `bunx oh-my-opencode-slim@latest doctor`
- OpenCode configuration, symlink, environment, and Herdr status checks
- Existing repository tests and `git diff --check`

After the user authenticates, verify the live setup with OpenCode's `ping all agents` prompt.

## References

- https://raw.githubusercontent.com/alvinunreal/oh-my-opencode-slim/refs/heads/master/README.md
- https://raw.githubusercontent.com/alvinunreal/oh-my-opencode-slim/master/docs/installation.md
- https://raw.githubusercontent.com/alvinunreal/oh-my-opencode-slim/master/docs/configuration.md
- https://raw.githubusercontent.com/alvinunreal/oh-my-opencode-slim/master/docs/multiplexer-integration.md
