{
  description = "NixOS + niri + Noctalia desktop";

  inputs = {
    # Unstable tracks latest packages — you want this for niri/noctalia/quickshell,
    # which all move fast. Switch to nixos-25.11 (or whatever's current stable)
    # later if you want a calmer, less bleeding-edge system.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Noctalia's own flake gets you the latest git version + its NixOS/Home-Manager
    # modules. nixpkgs also ships a `noctalia-shell` package directly if you'd
    # rather stay fully inside nixpkgs — see the commented-out alternative in
    # home/home.nix.
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, noctalia, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      # `desktop` is the hostname. Rename it to whatever you want your machine
      # called, and keep it consistent with hosts/desktop/configuration.nix and
      # your `sudo nixos-rebuild switch --flake .#desktop` command.
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/desktop/configuration.nix
          inputs.noctalia-greeter.nixosModules.default

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            # CHANGE "bonobones" to your actual username, here and in
            # hosts/desktop/configuration.nix
            home-manager.users.tibo = import ./home/home.nix;
          }
        ];
      };
    };
}
