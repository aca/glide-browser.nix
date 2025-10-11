{
  description = "flake for glide-browser";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs allSystems (
          system:
          f {
            inherit system;
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          }
        );
    in
    {
      packages = forAllSystems (
        {
          system,
          pkgs,
          ...
        }:
        let
          glide-browser = pkgs.stdenv.mkDerivation rec {
            pname = "glide-browser";
            version = "0.1.51a";

            src =
              let
                sources = {
                  "x86_64-linux" = pkgs.fetchurl {
                    url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.linux-x86_64.tar.xz";
                    sha256 = "1r8rnbgwhdqm639m5xixpw7b6v55rgjawjia5xp57g0pgyv243vr";
                  };
                  "aarch64-linux" = pkgs.fetchurl {
                    url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.linux-aarch64.tar.xz";
                    sha256 = "0yclrk760bjyss6w466xaaqq34hfrnh98sz1xf15m1hwjxa7l4vv";
                  };
                  "x86_64-darwin" = pkgs.fetchurl {
                    url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.macos-x86_64.dmg";
                    sha256 = "15iqc2x0d40s1kjvc0qzkyfgg6vfzbpg0y92r9asbxl2sjmwcc1w";
                  };
                  "aarch64-darwin" = pkgs.fetchurl {
                    url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.macos-aarch64.dmg";
                    sha256 = "1sq6j5siss02m2pg9hv4ahqfrl76xm8w2idbpw75p4vzl2a72yns";
                  };
                };
              in
              sources.${system};

            nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [
              pkgs.makeWrapper
            ];

            sourceRoot = ".";

            installPhase =
              if pkgs.stdenv.isLinux then
                ''
                  mkdir -p $out/bin $out/lib/glide
                  cp -r glide/* $out/lib/glide/
                  chmod +x $out/lib/glide/glide

                  makeWrapper ${pkgs.steam-run}/bin/steam-run $out/bin/glide \
                    --add-flags "$out/lib/glide/glide" \
                    --chdir $out/lib/glide

                  makeWrapper ${pkgs.steam-run}/bin/steam-run $out/bin/glide-browser \
                    --add-flags "$out/lib/glide/glide" \
                    --chdir $out/lib/glide
                ''
              else
                ''
                  mkdir -p $out/Applications
                  cp -r Glide.app $out/Applications/
                '';

            meta = {
              description = "Glide Browser";
              homepage = "https://github.com/glide-browser/glide";
              platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
            };
          };
        in
        {
          inherit glide-browser;
          default = glide-browser;
        }
      );
    };
}
