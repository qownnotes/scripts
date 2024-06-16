import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script provides integration for a local Ollama backend
 * See: https://github.com/ollama/ollama
 * List of models: https://github.com/ollama/ollama?tab=readme-ov-file#model-library
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
            "description": "The chat base URL of the Ollama API.",
            "type": "string",
            "default": "http://127.0.0.1:11434/v1/chat/completions",
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
                "id": "ollama",
                "name": "Ollama",
                "baseUrl": baseUrl,
                "models": models.split(",")
            },
        ];
    }
}
