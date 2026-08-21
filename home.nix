{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
    nerd-fonts.hack # the font everything renders in
    # holmes' setup
    ## cli
    zoxide
    eza
    bat
    yazi
    git-open
    ## neogit
    tree-sitter
    basedpyright
    ## runtimes
    bun
    nodejs
    ## dev
    docker-client
    colima
    ## misc
    mosh
    cloudflared
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables = {
    EDITOR = "nvim";
    OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS = "true";
    OPENCODE_ENABLE_EXA = "1";
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";

      # git
      gst = "git status --short -b";
      ga = "git add";
      gb = "git branch";
      gba = "git branch --all";
      gco = "git checkout";
      gc = "git commit";
      gf = "git fetch";
      gfa = "git fetch --all --tags --prune";
      glog = "git log --all --decorate --oneline --graph";
      gp = "git push";
      gpl = "git pull";
      grs = "git restore";
      grst = "git restore --staged";

      # eza
      ls = "eza --group-directories-first --icons=auto --color=auto";
      # long views
      l = "eza -blF --git --header --group-directories-first --icons=auto --color=auto";
      ll = "eza -la --git --header --octal-permissions --group-directories-first --icons=auto --color=auto";
      la = "eza -la --git --header --group-directories-first --icons=auto --color=auto";
      lm = "eza -l --git --header --sort=modified --reverse --group-directories-first --icons=auto --color=auto";
      # compact and specialist views
      l1 = "eza --oneline --group-directories-first --icons=auto --color=auto";
      lt = "eza --tree --level=2 --group-directories-first --icons=auto --color=auto";
      "l." = ''eza -a --oneline --color=never | grep -E "^\."''; 

      # yazi
      y = "yazi";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";

  # Keep Pi's credential and runtime state local by linking only authored files and directories.
  home.file.".pi/agent/themes".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/themes";
  home.file.".pi/agent/extensions".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions";
  home.file.".pi/agent/models.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/models.json";
  home.file.".pi/agent/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/settings.json";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/opencode.jsonc".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/opencode/opencode.jsonc";
  home.file.".config/opencode/tui.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/opencode/tui.json";
  home.file.".config/opencode/oh-my-opencode-slim.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/opencode/oh-my-opencode-slim.json";
  home.file.".config/opencode/plugins".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/opencode/plugins";
}
