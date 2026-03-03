{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  dependencies = [
    pkgs.libGL
    pkgs.xorg.libX11
    pkgs.xorg.libXi
    pkgs.libxkbcommon
    pkgs.wayland
  ];
  game = (config.languages.rust.import ./. {}).overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ dependencies;
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
    postFixup =
      (old.postFixup or "")
      + ''
        wrapProgram $out/bin/game \
          --set LD_LIBRARY_PATH ${lib.makeLibraryPath dependencies}
      '';
  });
in {
  cachix.push = "meenzen";
  cachix.pull = ["nix-community"];

  env.LD_LIBRARY_PATH = lib.makeLibraryPath dependencies;
  packages = [
    pkgs.git
  ];
  outputs = {
    inherit game;
  };

  languages.rust.enable = true;
  git-hooks.hooks = {
    alejandra.enable = true;
    actionlint.enable = true;
    check-added-large-files.enable = true;
    clippy.enable = true;
    end-of-file-fixer.enable = true;
    fix-byte-order-marker.enable = true;
    forbid-new-submodules.enable = true;
    nil.enable = true;
    rustfmt.enable = true;
    trim-trailing-whitespace.enable = true;
    cargo-test = {
      enable = true;
      name = "cargo test";
      pass_filenames = false;
      entry = "cargo test";
    };
  };
  devcontainer.enable = true;
}
