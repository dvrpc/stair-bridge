let
  pkgs = import <nixpkgs> {};
in pkgs.mkShell {
  buildInputs = [
    pkgs.python3
    pkgs.python3Packages.python-dotenv
    pkgs.python3Packages.psycopg2
    pkgs.python3Packages.python-lsp-server
  ];
}
