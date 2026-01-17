import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script provides integration for OpenRouter API
 * See: https://openrouter.ai/
 * Models: https://openrouter.ai/models
 * API docs: https://openrouter.ai/docs
 */
Script {
    property string apiKey
    property string apiBaseUrl
    property string models
    property string siteName
    property string siteUrl

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "apiKey",
            "name": "API Key",
            "description": "Your OpenRouter API key. Get one at https://openrouter.ai/keys",
            "type": "string",
            "default": ""
        },
        {
            "identifier": "apiBaseUrl",
            "name": "API base URL",
            "description": "The base URL of the OpenRouter API.",
            "type": "string",
            "default": "https://openrouter.ai/api/v1"
        },
        {
            "identifier": "models",
            "name": "Models",
            "description": "Comma separated list of model IDs to use. Examples: z-ai/glm-4.5-air:free,tngtech/deepseek-r1t-chimera:free",
            "type": "string",
            "default": "z-ai/glm-4.5-air:free,tngtech/deepseek-r1t-chimera:free,deepseek/deepseek-r1-0528:free"
        },
        {
            "identifier": "siteName",
            "name": "Site Name (Optional)",
            "description": "Your app name for OpenRouter rankings. Optional but recommended.",
            "type": "string",
            "default": "QOwnNotes"
        },
        {
            "identifier": "siteUrl",
            "name": "Site URL (Optional)",
            "description": "Your app URL for OpenRouter rankings. Optional but recommended.",
            "type": "string",
            "default": "https://www.qownnotes.org"
        },
    ]

    function init() {
        // Validate API key is set
        if (apiKey === '') {
            script.log('OpenRouter API key is not set. Please configure it in the script settings.');
            return;
        }

        // Try to fetch available models from OpenRouter
        try {
            const headers = {
                "Authorization": "Bearer " + apiKey,
                "Content-Type": "application/json"
            };

            // Note: QOwnNotes downloadUrlToString doesn't support custom headers easily
            // So we'll use the user-configured model list
            script.log('OpenRouter integration initialized with models: ' + models);
        } catch (e) {
            script.log('Error initializing OpenRouter: ' + e);
        }
    }

    /**
     * This function is called when the OpenAI service config is reloaded
     * It returns a list of objects with config parameters for new OpenAI backends
     */
    function openAiBackendsHook() {
        if (apiKey === '') {
            script.log('OpenRouter API key is not set. Skipping backend registration.');
            return [];
        }

        const baseUrl = apiBaseUrl + '/chat/completions';
        const modelList = models.split(",").map(function (model) {
            return model.trim();
        }).filter(function (model) {
            return model.length > 0;
        });

        if (modelList.length === 0) {
            script.log('No models configured for OpenRouter.');
            return [];
        }

        // Build extra headers for OpenRouter
        const extraHeaders = {
            "HTTP-Referer": siteUrl || "https://www.qownnotes.org",
            "X-Title": siteName || "QOwnNotes"
        };

        return [
            {
                "id": "openrouter",
                "name": "OpenRouter",
                "baseUrl": baseUrl,
                "apiKey": apiKey,
                "models": modelList,
                "extraHeaders": extraHeaders
            },
        ];
    }
}
