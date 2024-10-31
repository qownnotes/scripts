import QtQml 2.0
import QOwnNotesTypes 1.0

Script {

    function init() {
        script.registerCustomAction("ascii-tree-factory", "Generate ASCII tree from path"); 
    }

    function customActionInvoked(identifier) {
      switch (identifier) {
        case "ascii-tree-factory": { 
          var selection = script.noteTextEditSelectedText();
          // break selection strings at line ends
          var lines = selection.split("\n");
          // initialize tree object 
          var tree = {};
          //for each line in selection
          lines.forEach(function(line){
            // break line at slashes
            var path = line.split("/");
            var current = tree;
            // for each segment 
            path.forEach(function(subpath){
              // if the key doesn't have descendants, attach an empty object.
              if (!current[subpath]){
                current[subpath] = {};
              }
              // else move to the next level
              current = current[subpath];
            });
          });
          // uncomment for troubleshooting
          // script.log(JSON.stringify(tree));
          
          // Start rendering the codeblock with the "graphical" tree
          var codeBlockTree = `\`\`\`\n`;
          // init an array to keep track if each level is the last one at that depth
          var lastLevel = [];
          // recursive function to print the tree
          function printTree(tree, level){
            lastLevel.push(false);
            let keys =  Object.keys(tree);
            for (var k = 0;  k < keys.length; k++){
              if (k == (keys.length - 1)){
                lastLevel[level]=true;
              } else {
                lastLevel[level]=false;
              }
              // preparing the string that will be printed before the current key
              let previousLevelsRendering = "";
              for (var l = 0; l < level; l++){
                script.log ("current level: " + level + " key: " + keys[k] + " islastlevel? " + lastLevel[level]);
                // for each previous level print a "│ " if it's not the last key at that level
                previousLevelsRendering += lastLevel[l] ? "  " : "│ ";
              }
              // put together the string to be printed accounting for first level and last key at that level
              codeBlockTree += `${(level==0) ? keys[k] : previousLevelsRendering + (lastLevel[level]? "└─" : "├─" ) + keys[k]}\n`;
              printTree(tree[keys[k]], level + 1);
            }
          }
          // calling the recursive function
          printTree(tree, 0);
          // closing the codeblock
          codeBlockTree += `\`\`\``;
          script.noteTextEditWrite(codeBlockTree);
          break;
        }
      } 
    }
}