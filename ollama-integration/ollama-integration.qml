import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script provides integration for a local Ollama backend
 * See: https://github.com/ollama/ollama
 * List of models: https://github.com/ollama/ollama?tab=readme-ov-file#model-library
 * OpenAPI endpoint: https://ollama.com/blog/openai-compatibility or https://github.com/ollama/ollama/blob/main/docs/openai.md
 */
Script {
    property string apiBaseUrl;
    property string models;

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "apiBaseUrl",
            "name": "API base URL",
            "description": "The base URL of the Ollama API.",
            "type": "string",
            "default": "http://127.0.0.1:11434",
        },
        {
            "identifier": "models",
            "name": "Models",
            "description": "Comma separated list of models to use if no models were found.",
            "type": "string",
            "default": "llama3,gemma:2b",
        },
    ];

    function init() {
        const data = script.downloadUrlToString(this.apiBaseUrl + '/api/tags')

        if (data === '') {
            return;
        }

        const dataJson = JSON.parse(data);
        const modelNames = dataJson.models.map(model => model.model);

        if (modelNames.length > 0) {
            this.models = modelNames.join(',');
        }
    }

    /**
     * This function is called when the OpenAI service config is reloaded
     * It returns a list of objects with config parameters for new OpenAI backends
     */
    function openAiBackendsHook() {
        const baseUrl = this.apiBaseUrl + '/v1/chat/completions';

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
