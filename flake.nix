{
  description = "Rust Game";
  # Adapted from https://github.com/juspay/nix-rs/blob/main/flake.nix

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    rust-flake = {
      url = "github:juspay/rust-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # dev tools
    treefmt-nix.url = "github:numtide/treefmt-nix";
    just-flake.url = "github:juspay/just-flake";
    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.just-flake.flakeModule
        inputs.pre-commit-hooks-nix.flakeModule
        inputs.rust-flake.flakeModules.default
        inputs.rust-flake.flakeModules.nixpkgs
      ];
      systems = import inputs.systems;
      perSystem =
        { config
        , self'
        , inputs'
        , pkgs
        , lib
        , system
        , ...
        }:
        let
          dependencies = with pkgs; [
            libGL
            xorg.libX11
            xorg.libXi
            libxkbcommon
          ];
        in
        {
          rust-project.crates."game" = {
            crane.args = {
              buildInputs = dependencies;
            };
          };

          just-flake.features = {
            treefmt.enable = true;
            rust.enable = true;
            convco.enable = true;
            run = {
              enable = true;
              justfile = ''
                # Compile and run the project
                run:
                  cargo run
              '';
            };
          };

          # Add your auto-formatters here.
          # cf. https://numtide.github.io/treefmt/
          treefmt.config = {
            projectRootFile = "flake.nix";
            flakeCheck = false; # pre-commit-hooks.nix checks this
            programs = {
              nixpkgs-fmt.enable = true;
              rustfmt.enable = true;
            };
          };

          pre-commit = {
            check.enable = true;
            settings = {
              hooks = {
                treefmt.enable = true;
                convco.enable = true;
              };
            };
          };

          devShells.default = pkgs.mkShell {
            inputsFrom = [
              self'.devShells.rust
              config.treefmt.build.devShell
              config.just-flake.outputs.devShell
              config.pre-commit.devShell
            ];
            packages = [
              pkgs.cargo-watch
              config.pre-commit.settings.tools.convco
            ];
            buildInputs = dependencies;
            LD_LIBRARY_PATH = lib.makeLibraryPath dependencies;
          };
        };
    };
}
