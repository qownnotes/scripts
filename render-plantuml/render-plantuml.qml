import QtQml 2.0

/**
 * This script renders any plantuml text embedded in a note with the language hint, into a uml diagram.
 *
    * Dependencies:
    * java: https://java.com/en/download/
    * plantuml: http://plantuml.com/download
    *
    * Install java. download the plantuml jar and provide the full path to the script.
    *
 */
QtObject {
    property string javaExePath;
    property string plantumlJarPath;
    property string workDir;
    property string hideMarkup;
    property string noStartUml;
    property string svgOrPng;
    property string additionalParams;

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "javaExePath",
            "name": "Path to Java executable",
            "description": "Please enter path to your java executable, or just mention the 'java' if it is already on path:",
            "type": "file",
            "default": "java"
        },
        {
            "identifier": "plantumlJarPath",
            "name": "Path to plantuml jar",
            "description": "Please enter absolute path to plantuml jar file:",
            "type": "file",
            "default": "/opt/softs/plantuml/plantuml.jar"
        },
        {
            "identifier": "workDir",
            "name": "Working directory",
            "description": "Please enter a path to be used as working directory i.e. temporary directory for file creation:",
            "type": "file",
            "default": ""
        },
        {
            "identifier": "hideMarkup",
            "name": "Hide plantuml markup",
            "description": "Enable if you wish to hide plantuml markup in preview.",
            "type": "boolean",
            "default": false
        },
        {
            "identifier": "noStartUml",
            "name": "No need for @startuml/@enduml",
            "description": "Enable if you don't want to add @startuml/@enduml to your plantUml code (compat with tagging in note text)",
            "type": "boolean",
            "default": true
        },
        {
            "identifier": "svgOrPng",
            "name": "SVG output format (default: PNG)",
            "description": "Enable if you want to use SVG as output format instead of the default PNG format",
            "type": "boolean",
            "default": false
        },
        {
            "identifier": "additionalParams",
            "name": "Additional Params (Advanced)",
            "description": "Enter any additional parameters you wish to pass to plantuml. This can potentially cause unexpected behaviour:",
            "type": "string",
            "default": ""
        }
    ];

    function extractPlantUmlText(html, plantumlSectionRegex, note) {
        var plantumlFiles = [];
        var diagramsToGenerate = [];
        var index = 0;

        var match = plantumlSectionRegex.exec(html);
        while (match != null) {
            var filePath = script.getPersistentVariable("renderPlantUML/workDir") + "/" + note.id + "_" + (++index);
			//escape the \n into \|n
            var matchedUml = match[1].replace(/\\n/gm, "\\|n");
			//Unescape HTML entities because some special char are used by PlantUML
			matchedUml = unescape(matchedUml);
			// unescape \|n to a real escaped line break \n (cf. https://stackoverflow.com/questions/27363399/how-to-escape-line-break-already-present-in-a-string/27363443#27363443)
			matchedUml = matchedUml.replace(/(\\)\|n/gm, "\\n");


            if (noStartUml == "true") {
				// Transforms back tagged start/end keywords to @startkeyword/@endkeyword
                matchedUml = matchedUml.replace(/^<b><font color=\"\w+\">(start\w+)<\/font><\/b>\\n/gi, "@$1\\n").replace(/<b><font color=\"\w+\">(end\w+)<\/font><\/b>\\n$/gi, "@$1\\n");

                //If needed adds @startuml/@enduml
                if (!(matchedUml.match(/^\n?@start\w+(\n|\\n)/gi)))
					matchedUml = "@startuml\n" + matchedUml;
                if (!(matchedUml.match(/(\n|\\n)@end\w+\n?$/gi)))
					matchedUml = matchedUml + "\n@enduml\n";
            }

            matchedUml = matchedUml.replace(/&gt;/g, ">").replace(/&lt;/g, "<").replace(/"/g, "\"").replace(/&quot;/g, "\"").replace(/&amp;/g, "&").replace(/&#39;/g,"'").replace(/&#47;/g,"\/").replace(/&#40;/g,"\(").replace(/&#41;/g,"\)");

            script.log(`${filePath}`);

            var cached = isCached(filePath,matchedUml);
            script.log(cached);
            if (cached == "notCached") {
                script.writeToFile(filePath, matchedUml);
                diagramsToGenerate.push(filePath);
            }
            plantumlFiles.push(filePath);

            match = plantumlSectionRegex.exec(html);
        }

        if (diagramsToGenerate.length) generateUmlDiagrams(html, diagramsToGenerate);

        return plantumlFiles;
    }

    function generateUmlDiagrams(html, plantumlFiles) {
        var params = ["-jar", plantumlJarPath, "-o", script.getPersistentVariable("renderPlantUML/workDir"), "-t" + script.getPersistentVariable("renderPlantUML/svgOrPng"), additionalParams].concat(plantumlFiles);
        var result = script.startDetachedProcess(javaExePath, params, "plantuml-callback" + script.getPersistentVariable("renderPlantUML/noteId") ,0, html);
        script.setPersistentVariable("renderPlantUML/pumlRunning/" + script.getPersistentVariable("renderPlantUML/noteId"), "running")
    }

    function injectDiagrams(html, plantumlSectionRegex, plantumlFiles) {
        var index = 0;
        var updatedHtml = html.replace(plantumlSectionRegex, function(matchedStr, g1) {
            var imgElement = "<div><img src=\"file://" + plantumlFiles[index++] + "." + script.getPersistentVariable("renderPlantUML/svgOrPng") + "?t=" + +(new Date()) + "\" alt=\"Wait for it..\"/></div>";

            if (hideMarkup == "true") {
                return imgElement;
            } else {
                return imgElement + matchedStr;
            }
        });

        return updatedHtml;
    }
    // Check if the same plantUML content has already been saved
    // if an image was generated
    // and verify if it is the same
    function isCached(filePath,newContent) {
        var cached = "notCached";
        if(script.fileExists(filePath) && script.fileExists(filePath + "." + script.getPersistentVariable("renderPlantUML/svgOrPng"))){
            var oldContent = script.readFromFile(filePath);
            if (Qt.md5(oldContent) == Qt.md5(newContent))
                cached = "cached";
        }
        return cached;
    }

    function onDetachedProcessCallback(callbackIdentifier, resultSet, cmd, thread) {
        if (callbackIdentifier == "plantuml-callback" + script.getPersistentVariable("renderPlantUML/noteId")) {
            // If the flag is not set to done, then refresh
            if (script.getPersistentVariable("renderPlantUML/pumlRunning/" + script.getPersistentVariable("renderPlantUML/noteId")) != "done") {
                script.setPersistentVariable("renderPlantUML/pumlRunning/" + script.getPersistentVariable("renderPlantUML/noteId"), "done");
                script.regenerateNotePreview();
                script.log(`refresh`);
            } else {
                // else, reset the flag for the next modification
                script.setPersistentVariable("renderPlantUML/pumlRunning/" + script.getPersistentVariable("renderPlantUML/noteId"), "");
            }
        }
    }
    /**
     * This function is called when the markdown html of a note is generated
     *
     * It allows you to modify this html
     * This is for example called before by the note preview
     *
     * The method can be used in multiple scripts to modify the html of the preview
     *
     * @param {NoteApi} note - the note object
     * @param {string} html - the html that is about to being rendered
     * @param {string} forExport - the html is used for an export, false for the preview
     * @return {string} the modified html or an empty string if nothing should be modified
     */
     function noteToMarkdownHtmlHook(note, html, forExport) {
        script.log("launch");
        script.log(script.getPersistentVariable("renderPlantUML/pumlRunning/" + note.id));
        var plantumlSectionRegex = /<pre><code class=\"language-plantuml\"\>([\s\S]*?)(<\/code>)?<\/pre>/gmi;
        script.setPersistentVariable("renderPlantUML/workDir", workDir ? workDir: script.cacheDir("render-plantuml"));
        script.log(script.getPersistentVariable("renderPlantUML/workDir"));
        script.setPersistentVariable("renderPlantUML/svgOrPng", svgOrPng ? "svg":"png");
        script.log(script.getPersistentVariable("renderPlantUML/svgOrPng"));
        script.setPersistentVariable("renderPlantUML/noteId", note.id);
        script.log(script.getPersistentVariable("renderPlantUML/noteId"));

        var plantumlFiles = extractPlantUmlText(html, plantumlSectionRegex, note);

        if (plantumlFiles.length) {
            return injectDiagrams(html, plantumlSectionRegex, plantumlFiles);
        }
        return html;
    }
}
