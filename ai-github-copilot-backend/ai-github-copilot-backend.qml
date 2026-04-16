import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script adds GitHub Models to QOwnNotes, allowing you to use AI models
 * via your GitHub Copilot subscription through the GitHub Models inference API.
 *
 * Setup:
 * 1. Install this script in QOwnNotes (Settings > Scripting)
 * 2. Go to the script settings and enter your GitHub Personal Access Token
 *    (create one at https://github.com/settings/tokens — fine-grained
 *     with "Models: Read" permission, or a classic token)
 * 3. Once the script is active, you can choose the "GitHub" backend and
 *    your preferred model
 *
 */
Script {
    property string githubToken

    property variant settingsVariables: [
        {
            "identifier": "githubToken",
            "name": "GitHub Personal Access Token",
            "description": "Enter your GitHub PAT (create at https://github.com/settings/tokens).\nFine-grained: enable 'Models: Read' permission.\nClassic: the 'models' scope is needed.",
            "type": "string-secret",
            "default": ""
        }
    ]

    function openAiBackendsHook() {
        if (!githubToken || githubToken === "") {
            return [];
        }

        return [
            {
                "id": "github-models",
                "name": "GitHub",
                "baseUrl": "https://models.inference.ai.azure.com/chat/completions",
                "apiKey": githubToken,
                "models": ["gpt-4o", "gpt-4o-mini", "gpt-4.1", "gpt-4.1-mini", "gpt-4.1-nano", "gpt-5", "gpt-5-mini", "gpt-5-nano", "o4-mini", "o3", "o3-mini", "o1", "o1-mini", "deepseek-r1", "deepseek-r1-0528", "deepseek-v3-0324", "llama-4-scout-17b-16e-instruct", "llama-4-maverick-17b-128e-instruct-fp8", "llama-3.3-70b-instruct", "grok-3", "grok-3-mini", "mistral-small-2503", "phi-4", "phi-4-reasoning",]
            }
        ];
    }
}
