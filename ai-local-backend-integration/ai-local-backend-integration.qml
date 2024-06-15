import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script provides integration for a local AI backend
 * See: https://github.com/ollama/ollama
 *      https://github.com/ggerganov/llama.cpp
 * List of models: https://github.com/ollama/ollama?tab=readme-ov-file#model-library
 *                 https://github.com/ggerganov/llama.cpp#description
 * OpenAPI endpoint: https://ollama.com/blog/openai-compatibility or https://github.com/ollama/ollama/blob/main/docs/openai.md
 */
Script {
    property string baseUrl;
    property string models;

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "baseUrl",
            "name": "API base URL",
            "description": "The base URL of the local server.",
            "type": "string",
            "default": "http://127.0.0.1:11434",
        },
        {
            "identifier": "models",
            "name": "Models",
            "description": "Comma separated list of models to use.",
            "type": "string",
            "default": "llama3,gemma:2b",
        },
    ];

    /**
     * This function is called when the OpenAI service config is reloaded
     * It returns a list of objects with config parameters for new OpenAI backends
     */
    function openAiBackendsHook() {
        return [
            {
                "id": "local-ai",
                "name": "Local AI",
                "baseUrl": baseUrl + "/v1/chat/completions",
                "apiKey": "local-ai",
                "models": models.split(",")
            },
        ];
    }
}
