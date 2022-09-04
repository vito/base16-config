{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    let out = system:
      let
        pkgs = nixpkgs.legacyPackages."${system}";
        python-packages = ps: ps.callPackage ./python-packages.nix { };
        python-with-my-packages = pkgs.python3.withPackages (ps: with ps; [
          pip
          (python-packages ps)
        ]);
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            python-with-my-packages
          ];
          shellHook = ''
            export PIP_PREFIX=$(pwd)/_build/pip_packages
            export PYTHONPATH="$PIP_PREFIX/${pkgs.python3.sitePackages}:$PYTHONPATH"
            export PATH="$PIP_PREFIX/bin:$PATH"
            unset SOURCE_DATE_EPOCH
            pip install pybase16-builder
          '';
        };

        defaultPackage = with pkgs.poetry2nix; mkPoetryApplication {
          projectDir = ./.;
          preferWheels = true;
        };

        defaultApp = utils.lib.mkApp {
          drv = self.defaultPackage."${system}";
        };
      }; in with utils.lib; eachSystem defaultSystems out;
}
