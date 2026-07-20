{ config, pkgs, inputs, ... }:

{
  imports = [
    # Noctalia's Home Manager module — declaratively configures the shell itself
    # (color scheme, bar modules, panels) instead of hand-editing its settings file.
    inputs.noctalia.homeModules.default
    # Zen Browser — "beta" is the actively-updated channel; swap for "twilight"
    # or "twilight-official" if you want the more bleeding-edge builds instead.
    inputs.zen-browser.homeModules.beta
  ];

  home.username = "tibo"; # CHANGE to match flake.nix / configuration.nix
  home.homeDirectory = "/home/tibo";
  home.stateVersion = "25.11";

  # ---- Noctalia shell ----
  # Theming is intentionally left to Stylix here: once programs.noctalia.enable
  # is true, Stylix's own noctalia-shell target (auto-enabled, see
  # stylix.targets in configuration.nix) sets programs.noctalia.settings.theme
  # itself — a hand-mapped "stylix" custom palette built from the exact same
  # base16 colors used everywhere else, plus mode from stylix.polarity. Setting
  # theme.* here too would conflict with that (two definitions of the same
  # option) — Stylix's version is already the more coherent, pixel-matched one.
  programs.noctalia = {
    enable = true;
    # Full option list: https://docs.noctalia.dev
  };

  # ---- niri config file ----
  # niri's config is KDL, not native Nix (Home Manager has an experimental
  # `programs.niri.settings` module, but plain KDL is more stable right now
  # and every online example you find will be in this format).
  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;

  # ---- Zen Browser ----
  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
  };

  # ---- Your CLI favorites from this whole conversation ----
  home.packages = with pkgs; [
    eza
    zoxide
    fastfetch
    atuin
    bat
    ripgrep
    fd
    fzf
    dust
    bottom
    procs
    delta                  # nixpkgs attribute for the git-delta project
    tokei
    hyperfine
    just
    firefox               # kept as a fallback/compat browser alongside Zen

    # New this round
    vicinae               # launcher — packaged directly in nixpkgs now; also
                           # provides built-in clipboard history + emoji picker
    kdePackages.dolphin    # file manager
    kdePackages.ark        # archive tool, Dolphin's default "extract" action expects this
    wl-clipboard           # wl-copy / wl-paste — Wayland clipboard CLI, used by the `clip` fish function

    # GUI extras discussed earlier
    mission-center
    # bazaar is Flatpak-distributed rather than packaged in nixpkgs;
    # enable Flatpak support below if you want it.

    # ---- Desktop essentials that were missing ----
    hyprpolkitagent        # GUI polkit auth agent (drive mounting, NetworkManager, etc.)
                           # — despite the Hypr-branded name, works fine on niri/any wlroots
                           # compositor; if prompts don't appear, fall back to
                           # lxqt.lxqt-policykit-agent instead.
    xwayland-satellite     # X11 app compatibility — niri (25.08+) auto-spawns this
                           # on demand once it's on $PATH, no further config needed.

    # ---- Modern CLI tooling, fits the eza/bat/dust/fd aesthetic already established ----
    yazi                   # terminal file manager with image previews
    lazygit                # terminal git UI
    zellij                 # terminal multiplexer
    comma                  # `, <cmd>` — run any nixpkgs program ad-hoc without installing it
    papirus-icon-theme     # actual GTK icon theme (nothing set one before)
    satty                  # screenshot annotation, pairs with niri's Print binding

    (pkgs.callPackage ./packages/echo-music-desktop.nix { }) # "Echoes" — ad-free YouTube Music client
  ];

  # nh — nicer nixos-rebuild/home-manager-switch wrapper with pretty diffs
  programs.nh = {
    enable = true;
    flake = "/home/tibo/nix-setup";
  };

  # icon theme — Stylix themes colors/cursor/fonts but doesn't pick an icon set
  gtk.enable = true;
  gtk.iconTheme = {
    package = pkgs.papirus-icon-theme;
    name = "Papirus-Dark";
  };

  # Flatpak, for apps like Bazaar / anything not in nixpkgs
  # (enable the system service in configuration.nix: services.flatpak.enable = true;)

  programs.git = {
    enable = true;
    userName = "bonobones";
    userEmail = "mrbones0528@gmail.com";
  };

  # Bare package + niri's Mod+Return bind used to launch ghostty with zero
  # config; a real program module gives Stylix a config file to theme.
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
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
      # nh (nix-community/nh, enabled below with programs.nh.flake already
      # pointed at ~/nix-setup) wraps nixos-rebuild/nix flake update with
      # pretty generation diffs.
      rebuild = "nh os switch";
      update = "nh os update";
    };

    plugins = [
      # fzf-fish wires fzf into fish's own tab-completion and Ctrl+R history
      # search, on top of the atuin/fzf integration already enabled below.
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
      # done sends a desktop notification when a long-running command finishes
      # in a background/unfocused terminal — handy for slow rebuilds.
      { name = "done"; src = pkgs.fishPlugins.done.src; }
    ];

    functions = {
      # Usage: cat file.txt | clip   — copies stdin straight to the clipboard
      clip = "wl-copy";
    };
  };

  # wire up the CLI tools' shell integrations
  programs.zoxide.enable = true;
  programs.zoxide.enableFishIntegration = true;
  programs.atuin.enable = true;
  programs.atuin.enableFishIntegration = true;
  # Disables atuin's takeover of up-arrow and Ctrl+R — you get plain fish
  # history on up-arrow, and fzf-fish (already configured) owns Ctrl+R
  # instead, which is the search experience you said you preferred.
  programs.atuin.flags = [ "--disable-up-arrow" "--disable-ctrl-r" ];
  programs.fzf.enable = true;
  programs.fzf.enableFishIntegration = true;
  programs.starship.enable = true;

  # carapace — cross-shell completion engine, noticeably richer tab-completion
  # for many CLIs beyond fish's own built-in completions.
  programs.carapace = {
    enable = true;
    enableFishIntegration = true;
  };

  # nix-index — searchable database of every file in every nixpkgs package;
  # powers a "command not found -> here's the package" hint, and backs `comma`
  # (the `,` command in home.packages) for running programs ad-hoc.
  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };

  # Auto-lock on idle and before suspend — Noctalia has no reliable built-in
  # idle-timeout lock (confirmed buggy in its own issue tracker), so this
  # covers it with the same IPC command Mod+L already uses.
  services.swayidle = {
    enable = true;
    timeouts = [
      { timeout = 300; command = "qs -c noctalia-shell ipc call lockScreen lock"; }
    ];
    events = [
      { event = "before-sleep"; command = "qs -c noctalia-shell ipc call lockScreen lock"; }
    ];
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
