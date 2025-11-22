// ==========================================
// 1. REQUEST MODELS (Data sent to the API)
// ==========================================

/**
 * Represents a single message in the chat history.
 * Used for system instructions and user queries.
 */
export class MessageModel {
  role: string;
  content: string;

  constructor(role: string, content: string) {
    this.role = role;
    this.content = content;
  }
}

/**
 * Represents the payload sent to the OpenAI API.
 * Contains the model configuration and the message history.
 */
export class RequestModel {
  model: string;
  messages: MessageModel[];
  temperature: number;

  constructor(model: string, messages: MessageModel[], temperature: number) {
    this.model = model;
    this.messages = messages;
    this.temperature = temperature;
  }
}

// ===========================================
// 2. RESPONSE MODELS (Data received from the API)
// ===========================================

/**
 * The root object received from the API.
 * Contains either a list of choices (success) or an error object (failure).
 */
export class GPTResponse {
  choices: GPTChoice[] = [];
  error?: GPTError;
}

/**
 * Represents a generated response choice.
 */
export class GPTChoice {
  message: GPTMessage = new GPTMessage();
}

/**
 * Represents the content of the AI's message.
 */
export class GPTMessage {
  role: string = "";
  content: string = "";
}

/**
 * Represents an error returned by the API (e.g., invalid key).
 */
export class GPTError {
  message: string = "";
  type: string = "";
}