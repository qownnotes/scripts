# OpenRouter Integration

This script provides integration for [OpenRouter](https://openrouter.ai/), a unified API for accessing multiple AI models.

## Features

- Access to multiple AI models through a single API:
  - OpenAI (GPT-3.5, GPT-4, GPT-4 Turbo)
  - Anthropic (Claude 3 Opus, Sonnet, Haiku)
  - Google (Gemini Pro)
  - Meta (Llama 3)
  - And many more!

## Setup

1. Get an API key from [OpenRouter](https://openrouter.ai/keys)
2. Install this script in QOwnNotes
3. Configure the script settings:
   - **API Key**: Your OpenRouter API key (required)
   - **API base URL**: Default is `https://openrouter.ai/api/v1` (usually no need to change)
   - **Models**: Comma-separated list of model IDs you want to use
   - **Site Name** (optional): Your app name for OpenRouter rankings
   - **Site URL** (optional): Your app URL for OpenRouter rankings

## Model Configuration

You can configure which models to use in the script settings. Here are some popular models:

### OpenAI Models

- `openai/gpt-4-turbo-preview`
- `openai/gpt-4`
- `openai/gpt-3.5-turbo`

### Anthropic Models

- `anthropic/claude-3-opus`
- `anthropic/claude-3-sonnet`
- `anthropic/claude-3-haiku`

### Google Models

- `google/gemini-pro`
- `google/gemini-pro-vision`

### Meta Models

- `meta-llama/llama-3-70b-instruct`
- `meta-llama/llama-3-8b-instruct`

### Other Models

- `mistralai/mistral-large`
- `cohere/command-r-plus`
- `perplexity/llama-3-sonar-large-32k-online`

For a complete list of available models, see [OpenRouter Models](https://openrouter.ai/models).

## Example Configuration

Default models (budget-friendly):

```
openai/gpt-3.5-turbo,anthropic/claude-3-haiku,google/gemini-pro,meta-llama/llama-3-8b-instruct
```

Premium models:

```
openai/gpt-4-turbo-preview,anthropic/claude-3-opus,google/gemini-pro,meta-llama/llama-3-70b-instruct
```

## Cost

OpenRouter charges based on the models you use. Check [OpenRouter pricing](https://openrouter.ai/models) for current rates. Most models are pay-per-use with no subscription required.

## Links

- [OpenRouter Website](https://openrouter.ai/)
- [API Documentation](https://openrouter.ai/docs)
- [Model Library](https://openrouter.ai/models)
- [Get API Key](https://openrouter.ai/keys)
