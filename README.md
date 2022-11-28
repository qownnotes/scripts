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
[![Gitter chat](https://badges.gitter.im/gitterHQ/gitter.png)](https://gitter.im/qownnotes/qownnotes)

Here you will find the scripts you can directly access in [QOwnNotes](http://www.qownnotes.org), the plain-text file notepad with markdown support and Nextcloud and ownCloud integration.

Please visit the [Scripting documentation](https://docs.qownnotes.org/en/latest/scripting/) for more information about scripting and how to write your own.

## Contributing

To bring your script into the **script repository** you just have to do the following:

- **[fork](https://help.github.com/articles/fork-a-repo/)** the repository <https://github.com/qownnotes/scripts> on GitHub
- checkout your forked repository with `git clone https://github.com/YOUR_GITHUB_NAME/scripts.git qownnotes-scripts`
- **duplicate** the **`example-script` folder** and give it a more descriptive name
- **add your script** to the folder and remove the `example-script.qml`
- **edit** the **`info.json`** to add your meta data and describe what your script is doing
  - you can use [example script info.json](https://jsoneditoronline.org/?url=https%3A%2F%2Fraw.githubusercontent.com%2Fqownnotes%2Fscripts%2Fmaster%2Fexample-script%2Finfo.json) to help you with the json encoding
  - if you are not sure which `minAppVersion` the commands you are using needs take the [current version](https://github.com/pbek/QOwnNotes/blob/master/src/version.h) of *QOwnNotes*
- **commit and push** your changes to your repository
- create a **[pull request](https://help.github.com/articles/creating-a-pull-request/)** to get your script merged into the QOwnNotes script repository

When editing an existing script in the github web interface, do the following:
- If you do not already have a fork:
  - Go to <https://github.com/qownnotes/scripts>.
  - Click the **Fork** button in the upper right of the screen (between **Watch** and **Star**).
  - Leave the defaults (recommended) and click the **Create Fork** button.
- In your fork, select the QML file to edit.
  - Make any desired changes.
  - Fill out the Commit changes fields.
  - If this is a personal fork, select 'Commit directly to master branch'.
  - Click **Commit changes** button.
- Select the associated `info.json` (it will be in the same folder).
  - Add your name as an author.
  - Increase the version number.
  - Ensure the `minAppVersion` reflects the correct version needed (if using new features).
  - Make any other changes.
  - Fill out the Commit changes fields.
  - If this is a personal fork, select 'Commit directly to master branch'.
  - Click **Commit changes** button.
- Create a pull request to qownnotes/scripts on the master branch.
