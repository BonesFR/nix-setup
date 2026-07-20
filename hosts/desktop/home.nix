{ config, pkgs, inputs, ... }:

{
  imports = [
    # Noctalia's Home Manager module — declaratively configures the shell itself
    # (color scheme, bar modules, panels) instead of hand-editing its settings file.
    inputs.noctalia.homeModules.default
  ];

  home.username = "tibo"; # CHANGE to match flake.nix / configuration.nix
  home.homeDirectory = "/home/tibo";
  home.stateVersion = "25.11";

  # ---- Noctalia shell ----
  programs.noctalia = {
    enable = true;
    # Full option list: https://docs.noctalia.dev
    settings = {
      # Example: swap to a different accent scheme. Leave default to start,
      # tweak once you see it running.
      # colorScheme = "dynamic"; # generates palette from your current wallpaper
    };
  };

  # ---- niri config file ----
  # niri's config is KDL, not native Nix (Home Manager has an experimental
  # `programs.niri.settings` module, but plain KDL is more stable right now
  # and every online example you find will be in this format).
  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;

  # ---- Zen Browser ----
  # Not yet in nixpkgs as a first-class package everywhere; if `pkgs.zen-browser`
  # isn't found when you build, grab it from a community flake instead
  # (e.g. github:MarceColl/zen-browser-flake) and add it as another flake input.

  # ---- Your CLI favorites from this whole conversation ----
  home.packages = with pkgs; [
    eza
    zoxide
    fastfetch
    atuin
    bat
    ripgrep
    fzf
    dust
    bottom
    procs
    git-delta
    tokei
    hyperfine
    just
    ghostty

    # GUI extras discussed earlier
    mission-center
    # bazaar is Flatpak-distributed rather than packaged in nixpkgs;
    # enable Flatpak support below if you want it.
  ];

  # Flatpak, for apps like Bazaar / anything not in nixpkgs
  # (enable the system service in configuration.nix: services.flatpak.enable = true;)

  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "you@example.com";
  };

  programs.fish = {
    enable = true;

    # Show fastfetch instead of the default fish greeting on every new shell.
    interactiveShellInit = ''
      set fish_greeting
      fastfetch
    '';

    # Swap the classic Unix tools for the modern replacements we installed,
    # so muscle memory (`ls`, `cat`, `top`...) gets the better tool for free.
    shellAliases = {
      ls = "eza --icons --group-directories-first";
      ll = "eza -l --icons --group-directories-first";
      la = "eza -la --icons --group-directories-first";
      tree = "eza --tree --icons";
      cat = "bat";
      du = "dust";
      top = "btm";
      ps = "procs";
      find = "fd";
      grep = "rg";
      diff = "delta";
    };

    # Abbreviations expand inline as you type (unlike aliases) — good for
    # longer commands you want to see spelled out before they run.
    shellAbbrs = {
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph --decorate";
      gd = "git diff";
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#desktop";
      update = "cd ~/nixos-config && nix flake update && cd -";
    };

    plugins = [
      # fzf-fish wires fzf into fish's own tab-completion and Ctrl+R history
      # search, on top of the atuin/fzf integration already enabled below.
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
      # done sends a desktop notification when a long-running command finishes
      # in a background/unfocused terminal — handy for slow rebuilds.
      { name = "done"; src = pkgs.fishPlugins.done.src; }
    ];
  };

  # wire up the CLI tools' shell integrations
  programs.zoxide.enable = true;
  programs.zoxide.enableFishIntegration = true;
  programs.atuin.enable = true;
  programs.atuin.enableFishIntegration = true;
  programs.fzf.enable = true;
  programs.fzf.enableFishIntegration = true;
  programs.starship.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
