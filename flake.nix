{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    geng.url = "git+https://github.com/kast-lang/geng?submodules=1";
    # geng.url = "git+file:///home/kuviman/projects/kast-lang/geng?submodules=1";
    flake-utils.url = "github:numtide/flake-utils";

    fmod-ks.url = "github:vesdev/fmod-ks";
  };
  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import inputs.nixpkgs { inherit system; };
        fmod-ks = inputs.fmod-ks.packages.${system}.default;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            inputs.geng.packages.${system}.default
            fmod-ks.runtimeLibs
            pkgs.just
            pkgs.caddy
            pkgs.butler
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath fmod-ks.runtimeLibs;
          FMOD_KS_PATH = "${fmod-ks}";

          shellHook = ''
            export FMOD_SDK="''${FMOD_SDK:-$PWD/fmod}"
            export CFLAGS="$CFLAGS ${pkgs.lib.concatStringsSep " " (fmod-ks.cflags { sdk = "$FMOD_SDK"; })}"

            export FMOD_WEB_SDK="''${FMOD_WEB_SDK:-$PWD/fmod-web}"
            export EMCC_FLAGS="$EMCC_FLAGS ${pkgs.lib.concatStringsSep " " (fmod-ks.webCflags { sdk = "$FMOD_WEB_SDK"; })}"
            # fmod docs JEBAITED
            export EMCC_FLAGS="$EMCC_FLAGS -sASYNCIFY=0"
          '';
        };
      }
    );
}
