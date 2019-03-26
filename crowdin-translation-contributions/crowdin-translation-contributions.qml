import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script creates a note text edit context menu item that parses text copied from 
 * https://crowdin.com/project/qownnotes/activity_stream and outputs a changelog translation log text
 */
QtObject {
    /**
     * Initializes the custom action
     */
    function init() {
        // create a menu entry
        script.registerCustomAction("insertTranslatorText", "Insert translation text", "Translations", "edit-paste", true, true);
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     * 
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        switch (identifier) {
            case "insertTranslatorText":
                // get the text that is currently in the clipboard
                var html = script.clipboard(true);

//                script.log(html);
                
                var activities = html.split('<div class="list-activity-action"');
//                 script.log(activities.length);
                //script.log(activities);
                
                var allNames = [];
                var allLanguages = [];

                for(var s = 0; s < activities.length; s++) {
                    var activity = activities[s];
                    //script.log(activity);
                    
                    var regExp = /<a class="user-link".+?href="https:\/\/crowdin.com\/profile\/(.+?)".+?>.+?<\/a>.+?suggested.+?into (.+?)<\/div>/im;
                    var match = regExp.exec(activity);
                    
                    if (match != null) {
//                         script.log(match.length);
                        var name = match[1].trim();
                        
                        if (allNames.indexOf(name) == -1) {
                            allNames.push(name);
                        }

                        var languages = match[2].split('in the file')[0].replace('Portuguese, Brazilian', 'Brazilian Portuguese').replace(' and', ', ').split(', ');
                        
                        for(var i = 0; i < languages.length; i++) {
                            var language = languages[i].trim();
                            
                            if (allLanguages.indexOf(language) == -1) {
                                allLanguages.push(language);
                            }
                        }

//                         script.log(name);
//                         script.log(languages);
                    }
                }
                
//                 script.log(allNames);
//                 script.log(allLanguages);

                if (allNames.length > 0) {
                    var message = '- added more ' + allLanguages.join(', ') + ' translation (thank you ' + allNames.join(', ') + ')\n';
                    script.log(message);
                    script.noteTextEditWrite(message);
                }

                break;
        }
    }
}
