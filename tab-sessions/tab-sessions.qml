import QtQml 2.0
import QOwnNotesTypes 1.0


Script {
    function init() {
        // Search for all tags titled according to Tab Sessions naming rule
        // and register related custom actions for each of them
        let searched_tags = script.searchTagsByName("[[");
        for (let i = 0; i < searched_tags.length; i++) {
            let tag_name = searched_tags[i]
            if (tag_name.startsWith('[[') && tag_name.endsWith(']]')) {
                // fetch the first tag object with an appropriate name
                let tag_obj = script.getTagByNameBreadcrumbList([tag_name], false);
                // create related custom action with button
                let session_name = tag_name.replace('[[', '').replace(']]', '');
                script.registerCustomAction(`openTabSession_${session_name}`, `Open Tab Session: ${session_name}`, tag_name);
            }
        }

        script.registerCustomAction("closeAllNotesTabs", "Close all notes tabs", "Close All Tabs");
    }

    function customActionInvoked(identifier) {
        if (identifier.startsWith("openTabSession")) {
            let desktop_tag = `[[${identifier.replace('openTabSession_', '')}]]`;
            // script.log(`The tag string is: ${desktop_tag}`);
            
            // Retrieve the tag object related to the Tab Session
            let tag_obj = script.getTagByNameBreadcrumbList([desktop_tag], false);
            let tag_notes = tag_obj.notes

            if (tag_notes.length === 0) {
                script.log(`No notes for tag ${desktop_tag} !`);
                return
            }
            
            // Close all currently opened note tabs
            while (mainWindow.removeNoteTab(0)) { }
            
            // First, replace the single open tab with the tag-related tab with index=0
            script.setCurrentNote(tag_notes[0], true)
            mainWindow.removeNoteTab(0)

            // Then, open the rest tag-related notes, starting from index=1
            let i = 1;
            let callBack = () => {
                // script.log(`Opening note ${i}: ${tag_notes[i]}`);
                script.setCurrentNote(tag_notes[i], true);
            }
            let stopConditionFunc = () => {
                i++;
                return (i === tag_notes.length)
            }

            timer.triggerUntil(1, callBack, stopConditionFunc)
        }
            
        else if (identifier === "closeAllNotesTabs") {
            // Close all opened note tabs
            while (mainWindow.removeNoteTab(0)) { };
        }
    }


    // https://stackoverflow.com/questions/28507619/how-to-create-delay-function-in-qml
    property QtObject timer: Timer {
        function triggerUntil(delayTime, callBack, stopConditionFunc, finalCallBack) {
            timer.triggered.connect(callBack);
            timer.triggered.connect(function release() {
                if (stopConditionFunc()) {
                    timer.stop();
                    timer.triggered.disconnect(callBack);
                    timer.triggered.disconnect(release);
                    if (finalCallBack) { finalCallBack() }
                }
            });
            
            timer.repeat = true
            timer.interval = delayTime;
            timer.start();
        }

        function triggerOnce(delayTime, callBack) {
            let busy = true
            timer.triggerUntil(
                delayTime, 
                () => { busy = false }, 
                () => { return busy === false; }, 
                callBack
            )
        }
    }
}