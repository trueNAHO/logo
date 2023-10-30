{
  description = "NAHO's logo";

  inputs = {
    flakeUtils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    preCommitHooks = {
      inputs = {
        flake-utils.follows = "flakeUtils";
        nixpkgs-stable.follows = "preCommitHooks/nixpkgs";
        nixpkgs.follows = "nixpkgs";
      };

      url = "github:cachix/pre-commit-hooks.nix";
    };
  };

  outputs = {
    self,
    flakeUtils,
    nixpkgs,
    preCommitHooks,
    ...
  }:
    flakeUtils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        checks = {
          preCommitHooks = preCommitHooks.lib.${system}.run {
            hooks = {
              alejandra.enable = true;
              convco.enable = true;
              yamllint.enable = true;
            };

            settings.alejandra.verbosity = "quiet";
            src = ./.;
          };
        };

        devShells.default = pkgs.mkShell {
          inherit (self.checks.${system}.preCommitHooks) shellHook;
        };

        packages.default = let
          file_prefix = "naho_logo";
          svg_file = "main.svg";
        in
          pkgs.stdenv.mkDerivation {
            buildPhase = ''
              parallel \
                --halt now,fail=1 \
                ' \
                  if [ "{3}" = "transparent" ] && [ "{4}" = "jpg" ]; then \
                    exit 0; \
                  fi; \

                  file="${file_prefix}_{3}_{2}x{2}.{4}"; \

                  convert -background "{3}" -resize "{2}x" "{1}" "$file" && \
                  image_optim "$file" \
                ' \
                ::: "${svg_file}" \
                ::: 32 64 128 144 240 256 360 426 480 512 640 720 854 1024 \
                    1080 1280 1440 1920 2048 2160 2560 2880 3840 4096 \
                ::: aqua black blue fuchsia gray green lime maroon navy olive \
                    purple red silver teal transparent white yellow \
                ::: jpg png
            '';

            installPhase = ''
              mkdir --parent "$out"
              mv "${svg_file}" "$out/${file_prefix}.svg"
              mv *.jpg *.png "$out"
            '';

            name = "logo";
            nativeBuildInputs = with pkgs; [imagemagick image_optim parallel];
            src = ./src;
          };
      }
    );
}
