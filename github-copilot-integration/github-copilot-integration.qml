import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script provides integration for a local GitHub Copilot backend
 * See: https://github.com/ollama/ollama
 * List of models: https://github.com/ollama/ollama?tab=readme-ov-file#model-library
 * OpenAPI endpoint: https://ollama.com/blog/openai-compatibility or https://github.com/ollama/ollama/blob/main/docs/openai.md
 */
Script {
    property string apiBaseUrl
    property string apiKey
    property string models

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "apiBaseUrl",
            "name": "API base URL",
            "description": "The base URL of the GitHub Copilot API.",
            "type": "string",
            "default": "https://api.githubcopilot.com"
        },
        {
            "identifier": "apiKey",
            "name": "API Key",
            "description": "The API key for GitHub Copilot.",
            "type": "password",
            "default": ""
        },
        {
            "identifier": "models",
            "name": "Models",
            "description": "Comma separated list of models to use if no models were found.",
            "type": "string",
            "default": "gpt-3.5-turbo,gpt-3.5-turbo-0613,gpt-4o-mini,gpt-4o-mini-2024-07-18,gpt-4,gpt-4-0613,gpt-4-0125-preview,gpt-4o,gpt-4o-2024-11-20,gpt-4o-2024-05-13,gpt-4-o-preview,gpt-4o-2024-08-06,o1,o1-2024-12-17,o3-mini,o3-mini-2025-01-31,o3-mini-paygo,text-embedding-ada-002,text-embedding-3-small,text-embedding-3-small-inference,claude-3.5-sonnet,claude-3.7-sonnet,claude-3.7-sonnet-thought,gemini-2.0-flash-001,gemini-2.5-pro,gemini-2.5-pro-preview-05-06,o4-mini,o4-mini-2025-04-16,gpt-4.1,gpt-4.1-2025-04-14"
        },
    ]

    function init() {
        // const data = script.downloadUrlToString(apiBaseUrl + '/api/tags');

        // Fetch the models from the GitHub Copilot API
        var xhr = new XMLHttpRequest();
        xhr.open("GET", apiBaseUrl + "/models");
        xhr.setRequestHeader("Authorization", "Bearer " + apiKey);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.setRequestHeader("Copilot-Integration-Id", "vscode-chat");
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        // script.log(xhr.responseText);
                        // Extract only the model IDs
                        var modelIds = [];
                        if (response && response.data && Array.isArray(response.data)) {
                            for (var i = 0; i < response.data.length; i++) {
                                if (response.data[i].id) {
                                    modelIds.push(response.data[i].id);
                                }
                            }
                        }
                        if (modelIds.length > 0) {
                            models = modelIds.join(',');
                        }
                        script.log(JSON.stringify(models));
                    } catch (e) {
                        script.log("Failed to parse response: " + e);
                    }
                } else {
                    script.log("Request failed with status " + xhr.status);
                }
            }
        };
        xhr.send();
    }

    /**
     * This function is called when the OpenAI service config is reloaded
     * It returns a list of objects with config parameters for new OpenAI backends
     */
    function openAiBackendsHook() {
        const baseUrl = apiBaseUrl + '/chat/completions';

        return [
            {
                "id": "github-copilot",
                "name": "GitHub Copilot",
                "baseUrl": baseUrl,
                "models": models.split(",")
            },
        ];
    }
}
