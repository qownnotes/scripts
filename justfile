# Use `just <recipe>` to run a recipe
# https://just.systems/man/en/

# By default, run the `--list` command
default:
    @just --list

# Variables

transferDir := `if [ -d "$HOME/NextcloudPrivate/Transfer" ]; then echo "$HOME/NextcloudPrivate/Transfer"; else echo "$HOME/Nextcloud/Transfer"; fi`

# Aliases

alias fmt := format

# Apply the patch to the qownnotes-scripts repository
[group('patch')]
git-apply-patch:
    git apply {{ transferDir }}/qownnotes-scripts.patch

# Create a patch from the staged changes in the qownnotes-scripts repository
[group('patch')]
@git-create-patch:
    echo "transferDir: {{ transferDir }}"
    git diff --no-ext-diff --staged --binary > {{ transferDir }}/qownnotes-scripts.patch
    ls -l1t {{ transferDir }}/ | head -2

# Test the qownnotes-scripts repository
[group('test')]
@test:
    php ./.github/workflows/scripts/run-tests.php

# Add git commit hashes to the .git-blame-ignore-revs file
[group('linter')]
add-git-blame-ignore-revs:
    git log --pretty=format:"%H" --grep="^lint" >> .git-blame-ignore-revs
    sort .git-blame-ignore-revs | uniq > .git-blame-ignore-revs.tmp
    mv .git-blame-ignore-revs.tmp .git-blame-ignore-revs

# Format all files
[group('linter')]
format args='':
    nix-shell -p treefmt nodePackages.prettier shfmt nixfmt-rfc-style statix taplo kdePackages.qtdeclarative --run "treefmt {{ args }}"
