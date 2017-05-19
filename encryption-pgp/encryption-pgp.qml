import QtQml 2.0

/**
 * This script will encrypt and decrypt notes with PGP
 * 
 * You have to use your own public key instead of "F5161BD3"
 * Decryption will only work if you don't have to enter a password
 */
QtObject {
    property string gpgPath;
    property string publicKey;

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "gpgPath",
            "name": "GPG path",
            "description": "Please select the path to your <code>gpg</code> executable:",
            "type": "file",
            "default": "/usr/bin/gpg",
        },
        {
            "identifier": "publicKey",
            "name": "Public PGP Key",
            "description": "Please enter your public pgp key:",
            "type": "string",
            "default": "F5161BD3",
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
        // encrypt the text for public key or decrypt with gpg
        // decryption will only work if you don't have to enter a password
        var param = decrypt ? ["--decrypt"] : ["--encrypt", "--armor", "-r", publicKey];
        var result = script.startSynchronousProcess(gpgPath, param, text);
        return result;
    }
}
