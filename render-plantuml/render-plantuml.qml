import QtQml 2.0

/**
 * This script renders any plantuml text embedded in a note with the language hint, into a uml diagram.
 * 
    * Dependencies:
    * Node.js: https://nodejs.org/en/download/
    * java: https://java.com/en/download/
    * plantuml: http://plantuml.com/download
    * 
    * Install node and java. download the plantuml jar and provide the full path to the script.
    *
 */
QtObject {
    property string javaExePath;
    property string plantumlJarPath;
    property string workDir;

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
            "default": "/home/nikhil/softs/plantuml/plantuml.jar"
        },
        {
            "identifier": "workDir",
            "name": "Working directory",
            "description": "Please enter a path to be used as working directory i.e. temporary directory for file creation:",
            "type": "file",
            "default": "/tmp"
        }
    ];

    /**
     * This function is called when the markdown html of a note is generated
     * 
     * It allows you to modify this html
     * This is for example called before by the note preview
     * 
     * @param {Note} note - the note object
     * @param {string} html - the html that is about to being rendered
     * @return {string} the modfied html or an empty string if nothing should be modified
     */
    function noteToMarkdownHtmlHook(note, html) {
        var matches = html.match(/language-plantuml\"\>([\s\S]*?)<\/pre/gmi);

        var index = 0;
        html = html.replace(/<pre><code class=\"language-plantuml\"\>([\s\S]*?)<\/pre>/gmi, function(matchedStr, g1) {
        	var matchedUml = g1.replace(/\n/gi, "\\n");
			var filePath = workDir + "/" + note.id + "_" + (++index);
			var plantumlFilePath = filePath + ".plantuml";

			var params = ["-e", "require('fs').writeFileSync('" + plantumlFilePath + "', \"" + matchedUml + "\", 'utf8');"];
        	var result = script.startSynchronousProcess("node", params, html);
        	
//			script.log(additionalPumlParams);
        	params = ["-jar", plantumlJarPath, "-o", workDir, " ", plantumlFilePath];
        	result = script.startSynchronousProcess(javaExePath, params, html); //["-jar", plantumlJarPath, "-o", workDir, filePath]
        	
        	return "<div><img src=\"file://" + filePath + ".png\" alt=\"Wait for it..\"/></div>" + matchedStr;
        });
        
        return html;
    }
}

// Future plans:
// TODO: Allow for passingin addtional parameters to plantuml.
// TODO: Allow for replacing the markup in the rendered preview with image instead of keeping both.
// TODO: Optimize image creation by combining img generation in a single java command instead of in a loop.


