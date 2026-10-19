{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    geng.url = "git+https://github.com/kast-lang/geng?submodules=1";
    # geng.url = "git+file:///home/kuviman/projects/kast-lang/geng?submodules=1";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import inputs.nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            inputs.geng.packages.${system}.default
            pkgs.just
            pkgs.caddy
            pkgs.butler
          ];
        };
      }
    );
}
