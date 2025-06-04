{
  pkgs,
  ...
}:

{
  # https://devenv.sh/packages/
  packages = with pkgs; [
    just

    # Packages for treefmt
    nodePackages.prettier
    shfmt
    nixfmt-rfc-style
    statix
    taplo
    kdePackages.qtdeclarative
  ];

  # https://devenv.sh/languages/
  languages.php.enable = true;

  # https://devenv.sh/git-hooks/
  git-hooks.hooks.treefmt.enable = true;

  # https://devenv.sh/tests/
  enterTest = ''
    echo "?? Running tests"
    just test
  '';

  # See full reference at https://devenv.sh/reference/options/
}
