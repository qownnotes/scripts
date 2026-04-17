import QtQml 2.0
import QOwnNotesTypes 1.0

Script {
    property variant additionalParams: {
        "created_at": null,
        "id": null,
        "url": null
    }
    property string authCode
    property variant currentParams: {
        "visibility": null,
        "local_only": null,
        "sensitive": null,
        "spoiler_text": null,
        "language": null
    }
    property string language
    property bool local_only
    property string mySignature
    property bool sensitive
    property string serverInstance
    property variant settingsVariables: [
        {
            "identifier": "serverInstance",
            "name": "Server instance",
            "description": "Server instance you want to connect to (i.e.: example.org - no spaces, no protocol, no slashes)",
            "type": "string",
            "default": "example.org"
        },
        {
            "identifier": "authCode",
            "name": "Authorization Code",
            "description": "Code returned after performing a successful authentication, if you paste it here you won't need to authenticate again until expiry",
            "type": "string-secret",
            "default": ""
        },
        {
            "identifier": "mySignature",
            "name": "Post signature",
            "description": "This is a signature that will be appended to your GtS posts.",
            "type": "text",
            "default": "Sent from #QOwnNotes using #P2F"
        },
        {
            "identifier": "visibility",
            "name": "Visibility",
            "description": "Default visibility for published posts",
            "type": "selection",
            "default": "public",
            "items": {
                "public": "Public",
                "unlisted": "Unlisted",
                "private": "Private",
                "mutuals_only": "Mutuals (not supported by Mastodon)",
                "direct": "Direct Message"
            }
        },
        {
            "identifier": "local_only",
            "name": "Local only",
            "description": "If the post is local only, it will not be seen from federated instances. Not supported by Mastodon",
            "text": "Yes, let it be Local Only",
            "type": "boolean",
            "default": false
        },
        {
            "identifier": "sensitive",
            "name": "Content Warning",
            "description": "The post text will not be immediately visible, as it may be sensible to some audience",
            "text": "Yes, the post content is usually sensible",
            "type": "boolean",
            "default": false
        },
        {
            "identifier": "spoiler_text",
            "name": "Content Warning text",
            "description": "Text to show as a content warning for senstitive posts",
            "type": "string",
            "default": ""
        },
        {
            "identifier": "language",
            "name": "Language code",
            "description": "2-chars laguage code as per <a href='https://www.loc.gov/standards/iso639-2/php/English_list.php'>https://www.loc.gov/standards/iso639-2/php/English_list.php</a>:",
            "type": "string",
            "default": "en"
        },
    ]
    property string spoiler_text
    property string visibility

    function confirmDuplicatePost() {
        let msgText = `The current note Post Header contains "created_at" property. This may indicate that the note was already published. Are you sure you want to publish the note <b>again</b>?`;
        return (script.questionMessageBox(msgText, "P2F: publish duplicate note", 0x00000400 | 0x00400000) == 1024);
    }

    // This function ask user confirmation to generate a postHeader for the current post
    function confirmFrontmatter() {
        let msgText = `The current note does not appear to have a valid frontmatter for publishing. You can:<ul>`;
        msgText += `<li>Press "<b>OK</b>" to publish the note with default settings</li>`;
        msgText += `<li>Press "<b>Apply</b>" to cancel the publishing and generate a frontmatter for your note</li>`;
        msgText += `<li>Press "<b>Cancel</b>" to cancel the publishing</li></ul>`;
        msgText += `<b>Note:</b>Generating a frontmatter will add it on top of the note.`;
        return script.questionMessageBox(msgText, "P2F: missing frontmatter", 0x00000400 | 0x02000000 | 0x00400000);
    }

    // This function shows a confirmation message box with current note posting parameters
    function confirmPublish() {
        let msgText = "<b>You are about to publish the current note</b> with the following settings:\n<ul>";
        Object.keys(currentParams).forEach(function (key) {
            msgText += "<li>" + key + ": " + currentParams[key] + "</li>";
        });
        msgText += "</ul>";
        msgText += `Press "<b>Ok</b>" to confirm and post the note with the above settings;`;
        msgText += `Press "<b>Cancel</b>" to continue editing your note.`;
        return (script.questionMessageBox(msgText, "P2F: confirm publishing", 0x00000400 | 0x00400000) == 1024);
    }

    // This function generates a Post Header with comments and default parameter values for the current note.
    // if includeAdditional = true adds additional attributes (like created_at for already published notes)
    function generateFrontmatter(includeAdditional) {
        let frontMatter = "";
        frontMatter += "***Publish to Fediverse - frontmatter***\n";
        frontMatter += "\n";
        frontMatter += "#Edit the values to adjust the post settings.\n";
        frontMatter += "#Missing properties will be defaulted as per script settings.\n";
        frontMatter += "#Confirmation will be asked before publishing.\n";
        frontMatter += "#This section will not be published.\n";
        frontMatter += "\n";
        // checking all post parameters in currentParams against user settings params
        Object.keys(currentParams).forEach(function (key) {
            // using .every to break out the cycle
            settingsVariables.every(function (varObj) {
                if (key == varObj.identifier) {
                    // the eval used here is safe, as the variable it evaluates contains always a string value.
                    frontMatter += `${key}: ${eval(varObj.identifier)}${"\n"}`;
                    return false;
                } else {
                    return true;
                }
            });
        });
        if (includeAdditional) {
            Object.keys(additionalParams).forEach(function (key) {
                frontMatter += `${key}: ${additionalParams[key]}${"\n"}`;
            });
        }
        return frontMatter;
    }

    // This function updates the Frontmatter found in a Post with current parameter values for the current note.
    function updateFrontmatter() {
        let current = script.currentNote();
        let sections = current.noteText.split("---");
        script.tagCurrentNote("P2F");
        if (sections && sections[1]) {
            script.triggerMenuAction("actionAllow_note_editing", 1);
            mainWindow.focusNoteTextEdit();
            script.noteTextEditSetCursorPosition(0);
            script.noteTextEditSelectAll();
            script.noteTextEditWrite([sections[0], ("---\n" + generateFrontmatter(true) + "\n---")].concat(sections.slice(2)).join(""));
        }
    }

    // function that reads a Frontmatter section and populate the currentParams object
    function decodeFrontmatter(){ 
        let current = script.currentNote(); // current note    
        let postParams = {};
        let sections = current.noteText.split("---");
        if  (sections && sections[1]){
            sections[1].split("\n").forEach(function(param){
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
            script.log("P2F: Current note does not have a valid frontmatter.");
            return false;
        }
    }

    // This function parses a string for bool values or returns the original string
    function parseBool(val) {
        if (Object.prototype.toString.call(val) == "[object String]") {
            return val == "true" ? true : (val == "false" ? false : val);
        } else {
            return val === true || val === "true";
        }
    }

    // This function performs all API endpoint requests and returns text responses
    function request(verb, endpoint, aT, data) {
        // create request
        let xhr = new XMLHttpRequest();
        let url = "https://" + serverInstance + endpoint;
        // open synchronous request
        xhr.open(verb, url, false);
        // setting content type request header
        xhr.setRequestHeader("Content-Type", "application/json; charset=utf-8");
        // is accessToken is provided in the function call adding the Authorization header
        if (aT && aT.length > 0) {
            xhr.setRequestHeader("Authorization", "Bearer " + aT);
        }
        // sending the request with data, if date is there
        if (data) {
            // xhr.setRequestHeader("Content-Length", JSON.stringify(data).length);
            xhr.send(JSON.stringify(data));
        } else {
            xhr.send();
        }
        // since tha call is synchronous at this poit we already have the response
        // the response body is returned
        if (xhr.status == 200) {
            return xhr.response;
            // If the request is nor completed with a success code 200, write to che console the error and return null
        } else {
            script.log("P2F: Error: " + serverInstance + endpoint + " returned code " + xhr.status + " - " + xhr.statusText);
            script.log (JSON.stringify(xhr.response));
            script.log (xhr.getAllResponseHeaders());
            return null;
        }
    }
   
    // This function wraps the verify credential call
    function verifyCredentials(aT) {
        // calling the request over the specific endpoint, passing the accessToken
        let res = request("GET", "/api/v1/accounts/verify_credentials", aT);
        return res && true;
    }

    function customActionInvoked(identifier) {
        //handler for newPost command
        if (identifier == "newPost") {
            let date = new Date();
            let headline = "Note " + date.toISOString();
            script.createNote("# " + headline + "\n\n---\n\n" + generateFrontmatter() + "\n\n---\n\n");
            let currentNote = script.currentNote();
            script.triggerMenuAction("actionAllow_note_editing", 1);
            currentNote.renameNoteFile(headline);
            mainWindow.focusNoteTextEdit();
            script.tagCurrentNote("P2F");
            return;
        }

        // handler for publish command
        if (identifier == "publish") {
            // local variables init
            let clientName = "QONP2F";
            let clientMode = "read write profile";
            let clientId = "";
            let clientSecret = "";
            let oobCode = "";
            let accessToken = authCode;
            let credentialsVerified = false;
            let current = script.currentNote(); // current note
            let currentPost = ""; //current part of note that represents a post when frontmatter is stripped
            let instanceInfo = {};
            let maxCharsPerPost = 500; //default for Mastodon instances
            script.log("P2F: Applying signature to post - " + mySignature);
            if (!decodeFrontmatter()) {
                let exitCondition = true;
                let confirmResult = confirmFrontmatter();
                switch (confirmResult) {
                case 1024:
                    {
                        script.log("P2F: default posting settings confirmed.");
                        exitCondition = false;
                        break;
                    }
                case 33554432:
                    {
                        script.log("P2F: generating default frontmatter.");
                        // attach Post Header at the beginning of post
                        script.triggerMenuAction("actionAllow_note_editing", 1);
                        mainWindow.focusNoteTextEdit();
                        script.noteTextEditSetCursorPosition(0);
                        let date = new Date();
                        let headline = "Note " + date.toISOString();
                        script.noteTextEditWrite("# " + headline + "\n\n---\n\n" + generateFrontmatter() + "\n\n---\n\n");
                        script.tagCurrentNote("P2F");
                        exitCondition = true;
                        break;
                    }
                default:
                    {
                        script.log("P2F: publishing with current settings canceled.");
                        exitCondition = true;
                        break;
                    }
                }
                if (exitCondition)
                    return;
            }
            if (currentParams.created_at) {
                script.log("P2F: actual note may have already been published.");
                if (!confirmDuplicatePost()) {
                    return;
                }
            }
            if (confirmPublish()) {
                script.log("P2F: note publishing confirmed.");
                script.tagCurrentNote("P2F");
            } else {
                script.log("P2F: note publishing canceled.");
                return;
            }

            // If authCode (accessToken) is stored on user settings, recover and authenticate with it
            if (accessToken && accessToken.length > 0) {
                // authorization code was found, verifying credentials
                credentialsVerified = verifyCredentials(accessToken);
            } else {
                // start oob registering process
                let registerResponse = request("POST", "/api/v1/apps", "", {
                    "client_name": clientName,
                    "redirect_uris": "urn:ietf:wg:oauth:2.0:oob",
                    "scopes": clientMode
                });
                if (!registerResponse) {
                    return;
                }
                clientId = JSON.parse(registerResponse).client_id;
                clientSecret = JSON.parse(registerResponse).client_secret;

                // need to show a window with a http link for the user to click
                let authAddress = `https://${serverInstance}/oauth/authorize?client_id=${clientId}&redirect_uri=urn:ietf:wg:oauth:2.0:oob&response_type=code&scope=${clientMode}`;
                let popupTitle = "Out-of-band Authentication";
                let popupText = `<ol><li>Visit <a href="${authAddress}">this link</a></li><li>Paste your OOB authentication code below once authenticated</li></ol>`;
                //waiting for user to insert the authorzation code
                oobCode = script.inputDialogGetText(popupTitle, popupText, "OOB Authentication code here");
                if (!oobCode || oobCode.length == 0) {
                    script.log("P2F: No OOB Authentication code entered.");
                    return;
                }
                // exchanging for token
                let tokenRequest = request("POST", "/oauth/token", "", {
                    "redirect_uri": "urn:ietf:wg:oauth:2.0:oob",
                    "client_id": clientId,
                    "client_secret": clientSecret,
                    "grant_type": "authorization_code",
                    "code": oobCode
                });
                if (!tokenRequest) {
                    script.log("P2F: Unable to get access Token.");
                    return;
                } else {
                    accessToken = JSON.parse(tokenRequest).access_token;
                    credentialsVerified = verifyCredentials(accessToken);
                    script.informationMessageBox(`<p>You can copy and paste this Authorization code to the script user settings to avoid authenticating again:</p><h2>${accessToken}</h2>`, "Publish to Fediverse: Copy Authorization code");
                }
            }
            if (credentialsVerified) {
                script.log("P2F: Credentials verified!");
                //saving accessToken in a persistent variable called with the same name as the accessToken
                instanceInfo = JSON.parse(request("GET", "/api/v2/instance", accessToken));
                if (instanceInfo && instanceInfo.configuration.statuses["max_characters"]) {
                    maxCharsPerPost = instanceInfo.configuration.statuses["max_characters"];
                }
            } else {
                script.log("P2F: Credentials verification failed. Check the server or the internet connection and retry!");
                return;
            }
            // We can proceed with posting the actual note
            // Getting the current note markdown

            let sections = current.noteText.split("---");
            // posting only if text is present, excluding the Frontmatter, delimited by ---
            if (sections.length > 2 && (/./gm.test(sections[2]))) {
                currentPost = sections[2];
                // adding signature to the post
                if (mySignature && mySignature.length > 0) {
                    currentPost += "\n\n" + mySignature;
                }
            } else {
                script.log("P2F: Current note does not have a text to be published.");
                return;
            }
            if (currentPost.length > maxCharsPerPost) {
                script.log("P2F: Current note text is too long to be published.");
                script.informationMessageBox("Your note exceeds the maximum post length set by your instance server. Plaese shorten the note.", "Publish to Fediverse: length limit exceeded");
                return;
            }
            //populating the status object with status and post parameters
            let status = {
                "status": currentPost
            };

            Object.keys(currentParams).forEach(function (param) {
                status[param] = parseBool(currentParams[param]);
            });

            status.application = {
                name: "P2F script for QOwnNotes",
                website: "https://codeberg.org/77nn/QOwnNotes-personal-scripts"
            };

            let statusResult = JSON.parse(request("POST", "/api/v1/statuses", accessToken, status));
            if (statusResult && statusResult["created_at"]) {
                additionalParams["created_at"] = statusResult["created_at"];
                additionalParams["id"] = statusResult["id"];
                additionalParams["url"] = statusResult["url"];
                updateFrontmatter();
                script.tagCurrentNote("Published");
            }
            return;
        }
    }
 
    function init() {
        script.registerCustomAction("publish", "Publish to Fediverse", "", true, true, false);
        script.registerCustomAction("newPost", "New post for Fediverse", "", true, true, false);

        //validate server instance
        if (!(script.getPersistentVariable("publishToFedi/" + serverInstance))) {
            serverInstance = serverInstance.match(/(?!(\w+:\/\/))(\w+.)*(\w+)/g)[0];
        }
    }


}
