# QOwnNotes script repository

[Installation](http://www.qownnotes.org/installation) | 
[Changelog](https://github.com/pbek/QOwnNotes/blob/develop/CHANGELOG.md) | 
[Issues](https://github.com/qownnotes/scripts/issues) | 
[Releases](https://github.com/pbek/QOwnNotes/releases) |
[Documentation](http://docs.qownnotes.org) |
[IRC Chat](https://kiwiirc.com/client/irc.freenode.net/#qownnotes) |
[Gitter Chat](https://gitter.im/qownnotes/qownnotes)

[![Run tests](https://github.com/qownnotes/scripts/workflows/Run%20tests/badge.svg?branch=master)](https://github.com/qownnotes/scripts/actions)
[![Build Status](https://travis-ci.org/qownnotes/scripts.svg?branch=master)](https://travis-ci.org/qownnotes/scripts)
[![Percentage of issues still open](http://isitmaintained.com/badge/open/qownnotes/scripts.svg)](http://isitmaintained.com/project/qownnotes/scripts "Percentage of issues still open")
[![Gitter chat](https://badges.gitter.im/gitterHQ/gitter.png)](https://gitter.im/qownnotes/qownnotes)
[![Documentation](https://readthedocs.org/projects/qownnotes/badge/?version=develop)](http://docs.qownnotes.org)

Here you will find the scripts you can directly access in [QOwnNotes](http://www.qownnotes.org), the plain-text file notepad with markdown support and Nextcloud and ownCloud integration.

Please visit the [Scripting documentation](https://docs.qownnotes.org/en/latest/scripting/) for more information about scripting and how to write your own.

## Contributing

To bring your script into the **script repository** you just have to do the following:

- **[fork](https://help.github.com/articles/fork-a-repo/)** the repository <https://github.com/qownnotes/scripts> on GitHub
- checkout your forked repository with `git clone https://github.com/YOUR_GITHUB_NAME/scripts.git qownnotes-scripts`
- **duplicate** the **`example-script` folder** and give it an other descriptive name
- **add your script** to the folder and remove the `example-script.qml`
- **edit** the **`info.json`** to add your meta data and describe what your script is doing
  - you can use [example script info.json](https://jsoneditoronline.org/?url=https%3A%2F%2Fraw.githubusercontent.com%2Fqownnotes%2Fscripts%2Fmaster%2Fexample-script%2Finfo.json) to help you with the json encoding
  - if you are not sure which `minAppVersion` the commands you are using needs take the [current version](https://github.com/pbek/QOwnNotes/blob/master/src/version.h) of *QOwnNotes*
- **commit and push** your changes to your repository
- create a **[pull request](https://help.github.com/articles/creating-a-pull-request/)** to get your script merged into the QOwnNotes script repository
