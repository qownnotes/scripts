{
  pkgs,
  ...
}:

{
  packages = [ pkgs.qt6.qtdeclarative ];
  env.QML_TEST_IMPORT_PATH = "${pkgs.qt6.qtdeclarative}/lib/qt-6/qml";

  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    php-cs-fixer = {
      enable = true;
      entry = pkgs.lib.mkForce "${pkgs.phpPackages."php-cs-fixer"}/bin/php-cs-fixer fix";
      args = [
        "--config"
        "./.php-cs-fixer.dist.php"
      ];
      language = "system";
      pass_filenames = true;
      require_serial = true;
      stages = [ "pre-commit" ];
      types = [ "php" ];
    };

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
