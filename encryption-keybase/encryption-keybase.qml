import QtQml 2.0

/**
 * This script will encrypt and decrypt notes with https://keybase.io
 * 
 * You have to use your keybase user instead of "pbek"
 */
QtObject {
    property string kaybasePath;
    property string kaybaseUser;

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "kaybasePath",
            "name": "Keybase executable path",
            "description": "Please select the path to your <code>keybase</code> executable:",
            "type": "file",
            "default": "/usr/bin/keybase",
        },
        {
            "identifier": "kaybaseUser",
            "name": "Keybase user",
            "description": "Please enter your Keybase user name:",
            "type": "string",
            "default": "pbek",
        },
    ];

    /**
     * This is called when the script is loaded by QOwnNotes
     */
    function init() {
        // disable the password dialog
        script.encryptionDisablePassword();
    }

    /**
     * This function is called when text has to be encrypted or decrypted
     * 
     * @param text string the text to encrypt or descrypt
     * @param password string the password
     * @param decrypt bool if false encryption is demanded, if true decryption is demanded
     * @return the exncrypted or decrypted text
     */
    function encryptionHook(text, password, decrypt) {
        // encrypt or decrypt text with keybase.io for user pbek
        var param = decrypt ? ["decrypt"] : ["encrypt", kaybaseUser];
        var result = script.startSynchronousProcess(kaybasePath, param, text);
        return result;
    }
}
