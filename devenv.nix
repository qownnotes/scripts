{
  pkgs,
  ...
}:

{
  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    # Custom pre-commit hook to format justfile
    qmlformat = {
      enable = true;
      name = "qmlformat";
      entry = "${pkgs.qt6.qtdeclarative}/bin/qmlformat -i";
      language = "system";
      pass_filenames = true;
      stages = [ "pre-commit" ];
      files = "\\.qml$";
    };
  };

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
