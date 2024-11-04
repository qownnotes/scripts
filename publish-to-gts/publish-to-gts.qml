import QtQml 2.0
import QOwnNotesTypes 1.0

Script {
    property string serverInstance;
    property string authCode;
    property string visibility;
    property bool local_only;
    property bool sensitive;
    property string spoiler_text;
    property string language;
    
    property variant settingsVariables: [
        {
        "identifier": "serverInstance",
        "name": "Server instance",
        "description": "Server instance you want to connect to (i.e.: example.org - no spaces, no protocol, no slashes)",
        "type": "string",
        "default": "example.org",
        },
        {
        "identifier": "authCode",
        "name": "Authentication Code",
        "description": "Code returned by GtS after performing a successful authentication, if you paste it here you won't need to authenticate again until expiry",
        "type": "string-secret",
        "default": "",
        },
        {
        "identifier": "visibility",
        "name": "Visibility",
        "description": "Default visibility for published posts",
        "type": "selection",
        "default": "public",
        "items": {"public": "Public", "unlisted": "Unlisted", "private": "Private", "mutuals_only": "Mutuals", "direct": "Direct Message"},
        },
        {
        "identifier": "local_only",
        "name": "Local only",
        "description": "If the post is local only, it will not be seen from federated instances",
        "text": "Yes, let it be Local Only",
        "type": "boolean",
        "default": false,
        },
        {
        "identifier": "sensitive",
        "name": "Content Warning",
        "description": "The post text will not be immediately visible, as it may be sensible to some audience",
        "text": "Yes, the post content is usually sensible",
        "type": "boolean",
        "default": false,
        },
        {
        "identifier": "spoiler_text",
        "name": "Content Warning text",
        "description": "Text to show as a content warning for senstitive posts",
        "type": "string",
        "default": "Sensible content ahead!",
        },
        {
        "identifier": "language",
        "name": "Language code",
        "description": "2-chars laguage code as per <a href='https://www.loc.gov/standards/iso639-2/php/English_list.php'>https://www.loc.gov/standards/iso639-2/php/English_list.php</a>:",
        "type": "string",
        "default": "en",
        },
    ];  

    property variant currentParams: {
        "visibility": null,
        "local_only": null,
        "sensitive": null,
        "spoiler_text": null,
        "language": null
    }
    property variant additionalParams: {
        "created_at": null,
        "id": null,
        "url": null
    }

    function init() {
        script.registerCustomAction("publish", "Publish current note to GtS","",true,true,false);
        script.registerCustomAction("newPost", "New post for GtS","",true,true,false);

        //validate server instance
        if (!(script.getPersistentVariable("publishToGts/"+serverInstance))){
            serverInstance = serverInstance.match(/(?!(\w+:\/\/))(\w+.)*(\w+)/g)[0];   
        }
    }

    // This function returns a true or a false or a string that doesn't match true or false
    function parseBool(val) {
        if (Object.prototype.toString.call(val)=="[object String]"){
            return val == "true" ? true : (val == "false" ? false : val);
        } else {
            return val === true || val === "true";
        }
    }

    // This function generates a Post Header with comments and default parameter values for the current note.
    // if includeAdditional = true adds additional attributes (like created_at for already published notes)
    function generatePostHeader(includeAdditional){        
        let postHeader = "";
        postHeader += "***Publish to GtS - Post Header***\n";
        postHeader += "\n";
        postHeader += "#Edit the values to adjust the post settings.\n";
        postHeader += "#Missing properties will be defaulted as per script settings.\n";
        postHeader += "#Confirmation will be asked before publishing.\n";
        postHeader += "#This section will not be published.\n";
        postHeader += "\n";
        // checking all post parameters in currentParams against user settings params
        Object.keys(currentParams).forEach(function(key){
            // using .every to break out the cycle
            settingsVariables.every(function(varObj){
                if (key == varObj.identifier){
                    // the eval used here is safe, as the variable it evaluates contains always a string value.
                    postHeader += `${key}: ${eval(varObj.identifier)}${"\n"}`;
                    return false;
                } else {
                    return true;
                }
            });
        });
        if (includeAdditional){
            Object.keys(additionalParams).forEach(function(key){
                postHeader += `${key}: ${additionalParams[key]}${"\n"}`;
            });
        }
        return postHeader;
    }

    function updatePostHeader(){
        let current = script.currentNote()
        let sections = current.noteText.split("---"); 
        script.tagCurrentNote("Pub2GtS");
        if (sections && sections[1]){
            script.triggerMenuAction("actionAllow_note_editing", 1);
            mainWindow.focusNoteTextEdit();
            script.noteTextEditSetCursorPosition(0);
            script.noteTextEditSelectAll();
            script.noteTextEditWrite([sections[0], ("---\n" + generatePostHeader(true) + "\n---")].concat(sections.slice(2)).join(""));
        }
    }

    // function that reads a Post Header section and populate the currentParams object
    function decodePostHeader(){ 
        let current = script.currentNote(); // current note    
        let postParams = {};
        let postHeader = current.noteText.split("---");
        if  (postHeader[1]){
            postHeader[1].split("\n").forEach(function(param){
                if (! param.startsWith("#")){
                    let thisParam = param.split(":");
                    if (thisParam[0] && thisParam[1]){
                        postParams[thisParam[0].trim()]=param.split(":").slice(1).join("").trim();
                    }
                }
            });
            currentParams = postParams;
            return true;
        } else {
            script.log("Publish to GtS: Current note does not have a valid Post Header.");
            return false;
        }
    }

    // This function shows a confirmation message box with current note posting parameters
    function confirmPublish(){
        let msgText = "<b>You are about to publish the current note</b> with the following settings:\n<ul>";
        Object.keys(currentParams).forEach(function(key){
            msgText += "<li>" + key + ": " + currentParams[key] + "</li>";
        });
        msgText += "</ul>";
        msgText += `Press "<b>Ok</b>" to confirm and post the note with the above settings;`
        msgText += `Press "<b>Cancel</b>" to continue editing your note.`;
        return (script.questionMessageBox(msgText, "Publish to GtS: confirm action", 0x00000400|0x00400000) == 1024);
    }

    // This function ask user confirmation to generate a postHeader for the current post
    function confirmPostHeader(){
        let msgText = `The current note does not appear to have a valid Post Header for publishing. You can:<ul>`;
        msgText += `<li>Press "<b>OK</b>" to publish the note with default settings</li>`;
        msgText += `<li>Press "<b>Apply</b>" to cancel the publishing and generate a Post Header for your note</li>`;
        msgText += `<li>Press "<b>Cancel</b>" to cancel the publishing and add a Post Header manually</li></ul>`;
        msgText += `<b>Note:</b>Generating a Post Header will add the header <i>above</i> the title, if present.`; 
        return script.questionMessageBox(msgText, "Publish to GtS: missing Post Header", 0x00000400|0x02000000|0x00400000);
    }

    function confirmDuplicatePost(){
        let msgText = `The current note Post Header contains "created_at" property. This may indicate that the note was already published. Are you sure you want to publish the note <b>again</b>?`;
        return (script.questionMessageBox(msgText, "Publish to GtS: publish duplicate note", 0x00000400|0x00400000)==1024);
    }

    // This function performs all API endpoint requests and returns text responses
    function request(verb, endpoint, aT, data){
        // create request
        let xhr = new XMLHttpRequest();
        let url = "https://" + serverInstance + endpoint;
        // open synchronous request 
        xhr.open(verb, url, false);
        // setting content type request header
        xhr.setRequestHeader("Content-Type", "application/json; charset=utf-8");
        // is accessToken is provided in the function call adding the Authorization header
        if (aT && aT.length > 0){   
            xhr.setRequestHeader("Authorization", "Bearer " + aT);
        }
        // sending the request with data, if date is there
        if (data){
            // xhr.setRequestHeader("Content-Length", JSON.stringify(data).length);
            xhr.send(JSON.stringify(data));
        } else {
            xhr.send();
        }
        // since tha call is synchronous at this poit we already have the response
        // the response body is returned
        if (xhr.status == 200){
            return xhr.response;
        // If the request is nor completed with a success code 200, write to che console the error and return null
        } else {
            script.log ("Publish to GtS: Error: " + serverInstance + endpoint + " returned code " + xhr.status + " - " + xhr.statusText);
            script.log (JSON.stringify(xhr.response));
            script.log (xhr.getAllResponseHeaders());
            return null;
        }  
    }

    // This function wraps the "verify credential" call
    function verifyCredentials(aT){
        // calling the request over the specific endpoint, passing the accessToken
        let res = request ("GET", "/api/v1/accounts/verify_credentials", aT);
        return res && true;
    }

    function customActionInvoked(identifier) {

        //handler for newPost command
        if (identifier == "newPost"){
            let date = new Date();
            let headline = "Note " + date.toISOString();
            script.createNote("# " + headline + "\n\n---\n\n" + generatePostHeader() + "\n\n---\n\n");
            let currentNote = script.currentNote();
            script.triggerMenuAction("actionAllow_note_editing", 1);
            currentNote.renameNoteFile(headline);
            mainWindow.focusNoteTextEdit();
            script.tagCurrentNote("Pub2GtS");
            return;
        }

        // handler for publish command
        if (identifier == "publish") {
            // local variables init
            let clientName = "QONPublishToGts";
            let clientMode = "Read+Write";
            let clientId = "";
            let clientSecret = "";
            let credentialsVerified = false;
            let current = script.currentNote(); // current note
            let currentPost = ""; //current part of note that represents a post when post header stripped

            if (!decodePostHeader()){
                let exitCondition = true;
                let confirmResult = confirmPostHeader();
                switch (confirmResult){
                    case 1024:{
                        script.log("Publish to GtS: default posting settings confirmed.");
                        exitCondition = false;
                        break;
                    }
                    case 33554432:{
                        script.log("Publish to GtS: generating default Post Header.");
                        // attach Post Header at the beginning of post
                        script.triggerMenuAction("actionAllow_note_editing", 1);
                        mainWindow.focusNoteTextEdit();
                        script.noteTextEditSetCursorPosition(0);
                        let date = new Date();
                        let headline = "Note " + date.toISOString();
                        script.noteTextEditWrite("# " + headline + "\n\n---\n\n" + generatePostHeader() + "\n\n---\n\n");
                        script.tagCurrentNote("Pub2GtS");
                        exitCondition = true;
                        break;
                    }
                    default:{
                        script.log("Publish to GtS: publishing with current settings canceled.");
                        exitCondition = true;
                        break;
                    }
                }
                if (exitCondition) return;
            }
            if (currentParams.created_at){
                    script.log("Publish to Gts: actual note may have already been published.");
                    if (!confirmDuplicatePost()){
                        return;
                    }
                }
            if (confirmPublish()){
                script.log("Publish to GtS: note publishing confirmed.");
                script.tagCurrentNote("Pub2GtS");
            } else {
                script.log("Publish to GtS: note publishing canceled.");
                return;
             }

            // recover accessToken from persistent variables, if present
            let accessToken = script.getPersistentVariable("publishToGts/"+authCode);
            // check if accessToken was found on the persistent variables
            if (accessToken && accessToken.length > 0){
                // access token was found, verifying credentials
                credentialsVerified = verifyCredentials(accessToken);
            } else {
                let registerResponse = request("POST", "/api/v1/apps", "", {"client_name":clientName,"redirect_uris":"urn:ietf:wg:oauth:2.0:oob","scopes":clientMode});
                if (!registerResponse){
                    return;
                }
                clientId = JSON.parse(registerResponse).client_id;
                clientSecret = JSON.parse(registerResponse).client_secret;
                
                // need to show a window with a http link for the user to click
                let authAddress = `https://${serverInstance}/oauth/authorize?client_id=${clientId}&redirect_uri=urn:ietf:wg:oauth:2.0:oob&response_type=code&scope=${clientMode}`;
                let popupTitle = "GoToSocial Authentication";
                let popupText = `<ol><li>Visit <a href="${authAddress}">this link</a></li><li>Paste your code below once authenticated</li></ol>`;
                //waiting for user to insert the authorzation code
                authCode = script.inputDialogGetText(popupTitle, popupText, "Authorization code here");
                if (!authCode){
                    script.log("No authorization code entered.");
                    return;
                }
                script.log("authorization code inserted: " + authCode);
                // exchanging for token
                let tokenRequest = request("POST", "/oauth/token", "", {"redirect_uri": "urn:ietf:wg:oauth:2.0:oob","client_id": clientId, "client_secret": clientSecret,"grant_type": "authorization_code","code": authCode});
                script.log(tokenRequest);
                if (!tokenRequest){
                    script.log("Unable to get access Token.");
                    return;
                } else {
                    accessToken = JSON.parse(tokenRequest).access_token;
                    credentialsVerified = verifyCredentials(accessToken);
                }
            }
            if (credentialsVerified){
                script.log("Credentials verified!");
                //saving accessToken in a persistent variable called with the same name as the authCode
                script.setPersistentVariable("publishToGts/"+authCode, accessToken);
            } else {
                script.log("Credentials verification failed. Check the server or the internet connection and retry!");
                return;
            }
            // We can proceed with posting the actual note
            // Getting the current note markdown
            
            let noteSections = current.noteText.split("---");
            // posting only if text is present, excluding the Post Header, delimited by ---
            if (noteSections.length > 2 && /./gm.test(noteSections[2])){
                currentPost = noteSections[2];
            } else {
                script.log("Publish to GtS: Current note does not have a text to be published.")
                return;
            }
            //populating the status object with status and post parameters
            let status = {
                "status": currentPost
            };

            Object.keys(currentParams).forEach(function(param){
                status[param] = parseBool(currentParams[param]);
            });
        
            let statusResult = JSON.parse(request ("POST", "/api/v1/statuses", accessToken, status));
            if (statusResult && statusResult["created_at"]){
                additionalParams["created_at"] = statusResult["created_at"];
                additionalParams["id"] = statusResult["id"];
                additionalParams["url"] = statusResult["url"];
                updatePostHeader();
                script.tagCurrentNote("Published");
            }       
            return;
        }
    }
}
