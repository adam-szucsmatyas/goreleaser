{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    carlos.url = "github:caarlos0/nur";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { nixpkgs, carlos, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        cpkgs = carlos.packages.${system};
      in
      {
        packages.default = pkgs.buildGoModule {
          pname = "goreleaser";
          version = "unversioned";
          src = ./.;
          ldflags = [ "-s" "-w" "-X main.version=dev" "-X main.builtBy=flake" ];
          doCheck = false;
          vendorHash = "sha256-Z831RNML0A/oJmtG3kHCvdMgyC+ix2j25JbxtcZ/UnU=";
        };
        
        formatter = pkgs.nixpkgs-fmt;

        devShells.default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            go-task
            gofumpt
            syft
            upx
            cosign
            gnupg
            nix-prefetch
          ] ++ (lib.optionals pkgs.stdenv.isLinux [
            go_1_22
            snapcraft
          ]);

          shellHook = "go mod tidy";
        };

        devShells.docs = pkgs.mkShellNoCC {
          packages = with pkgs; with pkgs.python311Packages; [
            go-task
            htmltest
            mkdocs-material
            mkdocs-redirects
            mkdocs-minify
            cpkgs.mkdocs-rss-plugin # https://github.com/NixOS/nixpkgs/pull/277350
            cpkgs.mkdocs-include-markdown-plugin # https://github.com/NixOS/nixpkgs/pull/277351
          ] ++ mkdocs-material.passthru.optional-dependencies.git;
        };
      }
    );
}

