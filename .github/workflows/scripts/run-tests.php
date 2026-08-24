#!/usr/bin/env php
<?php

$dirs = array_filter(glob('*'), 'is_dir');
$testHelper = new TestHelper();

foreach ($dirs as $dir) {
    $testHelper->testDirectory($dir);
}

$errors = $testHelper->errors;
if (count($errors) > 0) {
    foreach ($errors as $dir => $scriptErrors) {
        print "Directory '$dir'\n";

        foreach ($scriptErrors as $error) {
            print "  $error\n";
        }
    }

    exit(1);
}

print "No errors were found\n";
exit(0);

class TestHelper
{
    public $errors = [];

    /**
     * Tests the files in a directory
     */
    public function testDirectory($dir)
    {
        $errors = [];
        $infoJson = $dir . "/info.json";

        if (preg_match('/[^a-z0-9\-]/', $dir)) {
            $errors[] = "$dir: Invalid characters were found in directory name '$dir'! Only lowercase letters, numbers and hyphens are allowed.";
        }

        $jsonData = file_get_contents($infoJson);
        $data = json_decode($jsonData, true);

        if ($data === null && json_last_error() !== JSON_ERROR_NONE) {
            $errors[] = "$infoJson: Failed to parse info.json: " . json_last_error_msg();
            $this->errors[$dir] = $errors;
            return;
        }

        if (!is_array($data)) {
            $errors[] = "$infoJson: info.json does not contain a valid object!";
            $this->errors[$dir] = $errors;
            return;
        }

        if (!isset($data["name"]) || $data["name"] == "") {
            $errors[] = "$infoJson: No name was entered!";
        }

        $identifier = $data["identifier"] ?? "";
        if ($identifier == "") {
            $errors[] = "$infoJson: No identifier was entered!";
        } elseif (preg_match('/[^a-z0-9\-]/', $identifier)) {
            $errors[] = "$infoJson: Invalid characters were found in identifier '$identifier'!";
        }

        if ($identifier != $dir) {
            $errors[] = "$infoJson: Identifier and directory name do not match!";
        }

        if (!isset($data["description"]) || $data["description"] == "") {
            $errors[] = "$infoJson: No description was entered!";
        }

        $script = $data["script"] ?? "";
        if ($script == "") {
            $errors[] = "$infoJson: No script was entered!";
        } elseif (!file_exists($dir . "/" . $script)) {
            $errors[] = "$dir/$script: Script '$script' doesn't exist!";
        }

        if (!isset($data["version"]) || $data["version"] == "") {
            $errors[] = "$infoJson: No version was entered!";
        }

        $errors = array_merge(
            $errors,
            $this->testChangelog($dir, $data["version"] ?? "")
        );

        // Check that extra .qml and .js files are listed in "resources"
        $extraFiles = array_filter(
            array_merge(glob($dir . "/*.qml"), glob($dir . "/*.js")),
            function ($file) use ($dir, $script) {
                return basename($file) !== $script;
            }
        );

        $resources = $data["resources"] ?? [];
        if (!is_array($resources)) {
            $errors[] = "$infoJson: 'resources' has to be an array!";
        } else {
            foreach ($extraFiles as $extraFile) {
                $basename = basename($extraFile);
                if (!in_array($basename, $resources)) {
                    $errors[] = "$extraFile: File '$basename' is not listed in 'resources' in info.json!";
                }
            }

            // Check that every file listed in "resources" actually exists
            foreach ($resources as $resource) {
                if (!file_exists($dir . "/" . $resource)) {
                    $errors[] = "$dir/$resource: Resource '$resource' listed in info.json doesn't exist!";
                }
            }
        }

        if (isset($data["platforms"])) {
            if (!is_array($data["platforms"])) {
                $errors[] = "$infoJson: 'platforms' has to be an array!";
            } else {
                foreach ($data["platforms"] as $platform) {
                    if (!in_array($platform, ["linux", "macos", "windows"])) {
                        $errors[] = "$infoJson: Unsupported platform '$platform', only 'linux', 'macos' and 'windows' are allowed!";
                    }
                }
            }
        }

        if (count($errors) > 0) {
            $this->errors[$dir] = $errors;
        }
    }

    /**
     * Tests that a script has a correctly formatted changelog for its current version
     */
    private function testChangelog($dir, $currentVersion)
    {
        $errors = [];
        $changelogFile = $dir . "/CHANGELOG.md";

        if (!is_file($changelogFile)) {
            return ["$changelogFile: Changelog doesn't exist!"];
        }

        $content = file_get_contents($changelogFile);
        if ($content === false) {
            return ["$changelogFile: Changelog could not be read!"];
        }

        $content = str_replace("\r\n", "\n", $content);
        if (!preg_match('/\A# Changelog\n(?:\n|$)/', $content)) {
            $errors[] = "$changelogFile: Changelog must start with a '# Changelog' heading!";
        }

        preg_match_all('/^## (\S+) - (\d{4})-(\d{2})-(\d{2})$/m', $content, $releases, PREG_OFFSET_CAPTURE);
        preg_match_all('/^## .*$/m', $content, $releaseHeadings);

        if (count($releases[0]) === 0) {
            $errors[] = "$changelogFile: No release entries were found! Expected '## VERSION - YYYY-MM-DD'.";
            return $errors;
        }

        if (count($releases[0]) !== count($releaseHeadings[0])) {
            $errors[] = "$changelogFile: Every release heading must use the format '## VERSION - YYYY-MM-DD'.";
        }

        $latestVersion = $releases[1][0][0];
        if ($currentVersion !== "" && $latestVersion !== $currentVersion) {
            $errors[] = "$changelogFile: Latest changelog version '$latestVersion' does not match info.json version '$currentVersion'!";
        }

        foreach ($releases[0] as $index => $release) {
            $year = (int) $releases[2][$index][0];
            $month = (int) $releases[3][$index][0];
            $day = (int) $releases[4][$index][0];
            if (!checkdate($month, $day, $year)) {
                $errors[] = "$changelogFile: Release '{$release[0]}' contains an invalid date!";
            }

            $sectionStart = $release[1] + strlen($release[0]);
            $sectionEnd = isset($releases[0][$index + 1])
                ? $releases[0][$index + 1][1]
                : strlen($content);
            $section = substr($content, $sectionStart, $sectionEnd - $sectionStart);
            if (!preg_match('/^- \S.*$/m', $section)) {
                $errors[] = "$changelogFile: Release '{$release[0]}' must contain at least one bullet entry!";
            }
        }

        return $errors;
    }
}
