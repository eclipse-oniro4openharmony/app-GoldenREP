import http from '@ohos.net.http';
import { WorkoutSet } from '../models/WorkoutModels';
import { PromptTemplates } from '../utils/PromptTemplates';
import { GPTResponse, MessageModel, RequestModel } from '../models/OpenAITypes';
import { AppConfig } from '../config/AppConfig';

export class LlmService {
  private readonly API_URL = AppConfig.OPEN_AI_API_BASE_URL;
  private readonly API_KEY = AppConfig.OPEN_AI_API_KEY;
  private readonly AI_MODEL = AppConfig.OPEN_AI_MODEL;

  /**
   * Sends workout data to ChatGPT for analysis.
   * @param workoutData The workout set object containing reps, failure reasons, etc.
   * @returns A Promise that resolves to the AI's response string.
   */
  async sendToChatGPT(workoutData: WorkoutSet): Promise<string> {
    // 1. Initialize the HTTP request object from the HarmonyOS network module
    const httpRequest = http.createHttp();
    // 2. Prepare the messages for the LLM
    // Create the system prompt (defines the AI's persona/rules) using the helper class
    const systemPrompt = new MessageModel("system", PromptTemplates.getSystemPrompt() );
    // Create the user prompt (contains the actual workout data) using the helper class
    const userMessage = new MessageModel("user", PromptTemplates.getUserPrompt(workoutData));
    // 3. Construct the request payload (the JSON body to be sent)
    const requestPayload = new RequestModel(
      this.AI_MODEL,       // The model to use
      [systemPrompt, userMessage], // The conversation history
      0.7              // Temperature (creativity level)
    );
    try {
      // 4. Execute the POST request
      const response = await httpRequest.request(
        this.API_URL,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.API_KEY}` // Authenticate with the API Key
          },
          extraData: JSON.stringify(requestPayload), // Serialize the payload object to a JSON string
          readTimeout: 10000,  // Stop waiting after 10 seconds (read)
          connectTimeout: 10000 // Stop waiting after 10 seconds (connect)
        }
      );
      // 5. Handle the response
      if (response.responseCode === 200) {
        // Success: Parse the result string into our typed GPTResponse object
        const apiResponse = JSON.parse(response.result.toString()) as GPTResponse;
        // Check if the AI returned any choices
        if (apiResponse.choices && apiResponse.choices.length > 0) {
          return apiResponse.choices[0].message.content;
        } else {
          return "No response received from model.";
        }
      } else {
        // API Error
        const apiResponse = JSON.parse(response.result.toString()) as GPTResponse;
        if (apiResponse.error) {
          // Return the specific error message from OpenAI
          return `API Error: ${apiResponse.error.message} (${apiResponse.error.type})`;
        }
        // Fallback for generic HTTP errors
        return `HTTP Error: ${response.responseCode}`;
      }
    } catch (error) {
      // 6. Handle Network Exceptions (e.g., no internet, timeout)
      return `Network Error: ${JSON.stringify(error)}`;
    } finally {
      // 7. Cleanup: Always destroy the request to free up system resources
      httpRequest.destroy();
    }
  }
}
