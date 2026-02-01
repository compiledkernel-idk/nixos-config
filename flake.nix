{
  description = "NixOS configuration with NAS support and Antigravity";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # You might need to adjust this URL to the correct one for your antigravity-nix flake
    # Google Antigravity IDE
    antigravity-nix.url = "github:jacopone/antigravity-nix"; 
  };

  outputs = { self, nixpkgs, home-manager, antigravity-nix, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix

          ({ ... }: {
            environment.systemPackages = [
              antigravity-nix.packages.${system}.default
            ];
          })
        ];
      };

      homeConfigurations.sultan = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ({ ... }: {
            home.username = "sultan";
            home.homeDirectory = "/home/sultan";
            home.stateVersion = "24.05";

            home.packages = [
              antigravity-nix.packages.${system}.default
            ];
          })
        ];
      };
    };
}
