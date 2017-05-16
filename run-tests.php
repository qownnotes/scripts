#!/bin/env php
<?php

$dirs = array_filter(glob('*'), 'is_dir');
$testHelper = new TestHelper();

foreach ($dirs as $dir) {
    $testHelper->testDirectory($dir);
}

$errors = $testHelper->errors;
if (count($errors) > 0) {
    foreach($errors as $dir => $scriptErrors) {
        print "Directory '$dir'\n";
        
        foreach($scriptErrors as $error) {
            print "  $error\n";
        }
    }
    
    exit(1);
}

print "No errors were found";


class TestHelper {
    public $errors = array();
    
    /**
     * Tests the files in a directory
     */
    public function testDirectory($dir) {
        $errors = array();
        $jsonData = file_get_contents($dir . "/info.json");
        $data = json_decode($jsonData, true);
        
        if ($data["name"] == "") {
            $errors[] = "No name was entered!";
        }
        
        if ($data["identifier"] == "") {
            $errors[] = "No identifier was entered!";
        }
        
        if ($data["description"] == "") {
            $errors[] = "No description was entered!";
        }
        
        $script = $data["script"];
        if ($script == "") {
            $errors[] = "No script was entered!";
        } elseif (!file_exists($dir . "/" . $script)) {
            $errors[] = "Script '$script' doesn't exist!";
        }
        
        if ($data["version"] == "") {
            $errors[] = "No version was entered!";
        }
        
        if (count($errors) > 0) {
            $this->errors[$dir] = $errors;
        }
    }
}
