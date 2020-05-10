import QtQml 2.14
import com.qownnotes.noteapi 1.0
import QtQuick 2.0


/**
 * This script creates LaTex images on the fly with KLatexFormula. e. g. $x^2$ or $[22] x^2$ to create larger images.
 * The images are created once and reused as long as the formula does not change.
 * If you changed the preamble you have to clean the tmp folder to regenerate the images.
 * Don't make it too complicated, this size works though: $[33] \\frac{1}{2\\pi}\\int{-\\infty}^{\\infty}e^{-\\frac{x^2}{a}}dx$
 * Hint: You might want to add the $-signs after writing the formula to prevent intermediate image generation.
 * test cmd: klatexformula -b '#ff0000' --latexinput '\delta(x) = \frac{1}{2\pi} \int e^{ikx}\,dk' --dpi 300 --output dirac-delta.png 
 */
QtObject {
    property string settingImageSize;
    property string settingDPI;
    property string executable;
    property string workDir
    property string formulaPrefix;
    property string formulaColor;
    property string formulaBgColor;
    property string usepackages;
    property string customPreamble;

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "settingImageSize",
            "name": "Default image height size",
            "description": "The default size of the LaTex image. Change it via parameter e. g. $[14] x^2$",
            "type": "integer",
            "default": "22"
        },
        {
            "identifier": "settingDPI",
            "name": "Default DPI",
            "description": "The default DPI used for the images.",
            "type": "integer",
            "default": "600"
        },
        {
            "identifier": "executable",
            "name": "Executable",
            "description": "Please enter a path to KLatexFormula",
            "type": "file",
            "default": "/usr/bin/klatexformula"
        },
        {
            "identifier": "workDir",
            "name": "Working directory",
            "description": "Please enter a path to be used as working directory i.e. temporary directory for file creation:",
            "type": "file",
            "default": "/tmp/qon/latex"
        },
        {
            "identifier": "formulaPrefix",
            "name": "Formula Prefix",
            "description": "Please enter a prefix for all formulas. Remember you might want to leave a space at the end.",
            "type": "string",
            "default": "\\bf "
        },
        {
            "identifier": "formulaColor",
            "name": "Formula Color",
            "description": "Use a different color. Useful for dark mode and the like. Format: #RRGGBB or '-' for transparent",
            "type": "string",
            "default": "#000000"
        },
        {
            "identifier": "formulaBgColor",
            "name": "Formula Background Color",
            "description": "Use a different color. Useful for dark mode and the like. Format: #RRGGBB or '-' for transparent",
            "type": "string",
            "default": "-"
        },
        {
            "identifier": "usepackages",
            "name": "Packages to include in the preamble",
            "description": "Enter the packages comma separated",
            "type": "string",
            "default": "amsmath,amssymb,amsfonts"
        },
        {
            "identifier": "customPreamble",
            "name": "Custom preamble commands",
            "description": "Enter the preamble commands",
            "type": "text",
            "default": "\\newcommand{\\mycmd}[1]{\\bf \\underline{#1}}"
        },
    ];

    function log(text){
        script.log("[LaTex] "+text)
    }

    /**
     * Initializes the custom action
     */
    function init() {
        log("init")
        var result = script.startSynchronousProcess("mkdir", ["-p", workDir]);
        // create a menu entry to paste Latex code as an image
        script.registerCustomAction("latex-math-refresh", "Refresh LaTex Images", "Latex", "view-refresh");
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
     * @return {string} the modified html or an empty string if nothing should be modified
     */
    function noteToMarkdownHtmlHook(note, html){
      // $ were replaced by <x-equation> tags
      //const regex_latex = /\$(?:\[(\d+)\])?([\s\S]+?)\$(?!\d)/g   // don't allow $4 as closing character
      const regex_latex = /(?:<x-equation>)(?:\[(\d+)\])?([\s\S]+?)(?:<\/x-equation>)/g   // don't allow $4 as closing character

      html = html.replace(regex_latex, function(match, matchImageSize, latex, offset) {

        let imageSize = settingImageSize;

        if(matchImageSize != null && matchImageSize.length > 0){
          imageSize = matchImageSize
        }

        var path = generateLaTexImage(latex)
        return `<img style='vertical-align: middle;' height='${imageSize}' src="${path}">`; //style='vertical-align: middle;'
      });
      return html
    }


    /**
     * Create the LaTex image
     * @return path
     */
    function generateLaTexImage(latex) {
      latex = formulaPrefix + latex // add prefix from settings
      log(latex)
      latex = latex.trim()
      function getPreamble(){
        var packages = usepackages.split(',')
        var preamble = ""
        // add packages
        packages.forEach(function myFunction(item) {
          preamble += `\\usepackage{${item}}`
        });
        // add custom preamble
        preamble += customPreamble
        return preamble
      }

      function getBash(isQuiet = true){
        const exec = executable
        const preamble = Qt.btoa(getPreamble())
        const quiet = isQuiet ? " --quiet 1" : ""; // --quiet OFF does not work (klatexformula bug?)
        const cmd = `${exec} -f '${formulaColor}' -b '${formulaBgColor}' --base64arg --preamble="${preamble}" --base64arg --latexinput="${base64Latex}" --dpi ${settingDPI} ${quiet} --output ${path}`
        //log("cmd: "+cmd)
        return cmd
      }

      const base64Latex = Qt.btoa(latex)
      const filename = base64Latex
      const path = workDir + "/" + filename + ".png"

      if (!fileExists(path)) { // performance: do not create the same formula twice
        // try to generate or prompt error msg
        if(!execBash(getBash())){ // check for result
          log(`[ERR]: ${latex} (${base64Latex})`)
          var bash = getBash(false)
          var result = execBashDetached(bash, true) // check result with non quiet bash cmd
          // more anoying than helpful
          //var result = execBash(bash, true) // check result with non quiet bash cmd
          //script.informationMessageBox("LaTex error, check the script log for more details.", "LaTex error")
          //log("[ERR]: "+result)
        }else{
          //log("[OK]: "+latex)
        }
      }
      return path
    }


    /**
     * check for a file
     *
     */
    function fileExists(path){
      return execBash(`test -f ${path}`)
    }


    /**
     * This function invoces a bash command
     * @return the result or [true/false] if detached = true
     */
    function execBashDetached(cmd){
        const exec = "bash"
        const param = ["-c", cmd]
        return script.startDetachedProcess(exec, param);
    }

    /**
     * This function invoces a bash command
     * @return the result or [true/false]
     */
    function execBash(cmd, getResult=false) {
      const prefix = "2>&1 " // use 2>&1 to redirect stderr to stdout and use as error msg
      const exec = "bash"
      const successSuffix = getResult ? "" : " && echo 1 || echo 0"
      const param = ["-c", prefix+cmd+successSuffix]
      var result = script.startSynchronousProcess(exec, param);
      return getResult ? String(result) : result == 1
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier !== "latex-math-refresh") {
            return;
        }
        log("refresh images")
        execBashDetached(`rm ${workDir}/*`) // clean the tmp dir
        script.regenerateNotePreview();
    }

}
