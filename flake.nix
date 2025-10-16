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
          glide-browser-unwrapped = pkgs.stdenv.mkDerivation rec {
            pname = "glide-browser";
            version = "0.1.53a";

            src =
              let
                sources = {
                  "x86_64-linux" = pkgs.fetchurl {
                    url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.linux-x86_64.tar.xz";
                    sha256 = "0iz4rr9hs1z2j5wcv61zb4vcvz9si71ln09lmkyyb55dhblshkxm";
                  };
                  "aarch64-linux" = pkgs.fetchurl {
                    url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.linux-aarch64.tar.xz";
                    sha256 = "1h9g1dx1zkj9qin3v73g1k8lf82rbkpprhdi506xg52a2j2adb8p";
                  };
                  "x86_64-darwin" = pkgs.fetchurl {
                    url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.macos-x86_64.dmg";
                    sha256 = "0ck1vw9s83gdas08pxnl08kdyil4pf5cqi29w7kpq6ygc2h43jfb";
                  };
                  "aarch64-darwin" = pkgs.fetchurl {
                    url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.macos-aarch64.dmg";
                    sha256 = "012wdy52202925gdq4x5sqirprfjl6js6qpfbxgpwmqf6zxqmwkk";
                  };
                };
              in
              sources.${system};

            nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isDarwin [ pkgs.undmg ];

            sourceRoot = ".";

            installPhase =
              if pkgs.stdenv.isLinux then
                ''
                  mkdir -p $out/lib/glide
                  cp -r glide/* $out/lib/glide/
                  chmod +x $out/lib/glide/glide
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

          glide-fhs = pkgs.buildFHSEnv {
            name = "glide-browser";
            targetPkgs = pkgs: with pkgs; [
              glide-browser-unwrapped
              gtk3
              gdk-pixbuf
              glib
              cacert
              dbus
              p11-kit
              at-spi2-atk
              at-spi2-core
              cups
              libdrm
              mesa
              expat
              alsa-lib
              nspr
              nss
              cacert
              pango
              cairo
              xorg.libX11
              xorg.libXcomposite
              xorg.libXdamage
              xorg.libXext
              xorg.libXfixes
              xorg.libXrandr
              libxkbcommon
            ];
            profile = ''
              export SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
              export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
            '';
            runScript = "${pkgs.bash}/bin/bash -c 'cd ${glide-browser-unwrapped}/lib/glide && exec ./glide \"\$@\"'";
          };

          glide-browser = if pkgs.stdenv.isLinux then glide-fhs else glide-browser-unwrapped;
        in
        {
          inherit glide-browser;
          default = glide-browser;
        }
      );
    };
}
