{
  pkgs,
  ...
}:

{
  # https://devenv.sh/packages/
  packages = with pkgs; [
    just
    php

    # Packages for treefmt
    nodePackages.prettier
    shfmt
    nixfmt-rfc-style
    statix
    taplo
    kdePackages.qtdeclarative
  ];

  # https://devenv.sh/git-hooks/
  git-hooks.hooks.treefmt.enable = true;

  enterShell = ''
    echo "🛠️ QOwnNotes scripts dev shell"
  '';

  # https://devenv.sh/tests/
  enterTest = ''
    echo "⚙️ Running tests"
    just test
  '';

  # See full reference at https://devenv.sh/reference/options/
}
