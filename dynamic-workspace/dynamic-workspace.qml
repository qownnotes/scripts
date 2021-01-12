import QtQml 2.0
import QOwnNotesTypes 1.0
import com.qownnotes.noteapi 1.0

/**
 * This script exports multiple notes as one HTML file
 */
Script {
    
    property string nonMaximizedWorkspaceName;
    property string maximizedWorkspaceName;
    
    property variant settingsVariables: [
        {
            "identifier": "nonMaximizedWorkspaceName",
            "name": "Non-maximized Workspace",
            "description": "Workspace to use when window is not maximized:",
            "type": "string",
            "default": "",
        },
        {
            "identifier": "maximizedWorkspaceName",
            "name": "Maximized Workspace",
            "description": "Workspace to use when window is maximized:",
            "type": "string",
            "default": "",
        }
    ];
    
    function windowStateChangedHook(windowState) {
        script.log('Window state changed: ' + windowState);
        var workspaceName = (windowState == 'nostate' ? nonMaximizedWorkspaceName : (windowState == 'maximized' ? maximizedWorkspaceName : ''));
        if (workspaceName) {
            var workspaceUuid = mainWindow.getWorkspaceUuuid(workspaceName);
            if (workspaceUuid) {
                mainWindow.setCurrentWorkspace(workspaceUuid);
            } else {
                script.log('Workspace with name ' + workspaceName + ' does not exist');
            }
        }
    }

}
