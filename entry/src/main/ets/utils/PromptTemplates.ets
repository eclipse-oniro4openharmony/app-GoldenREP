import { WorkoutSet } from '../models/WorkoutModels';

export class PromptTemplates {

  /**
   * SYSTEM PROMPT
   * Reduziert auf das Wesentliche: Persona und Output-Regeln.
   * Wir erklären nicht mehr WIE wir Fehler berechnen, sondern nur, dass die KI den Tags vertrauen soll.
   */
  static getSystemPrompt(): string {
    return `
# ROLE
You are a world-class High-Performance Fitness Coach.

# OBJECTIVE
Analyze the workout data timeline provided.
- **Trust the data:** If a rep is marked "FAILURE", it was a bad rep. No need to question why.
- **Detect Trends:** Look at how Duration and Heart Rate change from Rep 1 to the end.
- **Goal:** Provide **ONE** specific, human-like coaching tip for the next set.

# OUTPUT RULES
1. **Language:** English
2. **Length:** Maximum 30 words (Strict constraint).
3. **Tone:** Motivating start ("Great work!", "Keep pushing!"), then constructive advice.
4. **Logic:**
   - Duration goes up + Failure at the end -> Fatigue (Suggest dropping weight or breathing focus).
   - JITTER failure -> Stability issue (Suggest core tension).
   - SPEED failure -> Pace issue (Suggest "Slow down" or "Control the weight").

# EXAMPLES

Input: Reps 1-8 Perfect, Rep 9-10 Failure (SPEED), Duration spikes.
Output: "Strong fight! 🚀 You rushed the last reps as you got tired. Focus on a slow, controlled tempo even when it burns."

Input: Early Failure (JITTER).
Output: "Good start, but you're shaking. 🧠 Tighten your core and lower the weight slightly to master the stability first."
`.trim();
  }

  /**
   * USER PROMPT
   * Bereitet die Daten auf.
   * ÄNDERUNG: Kein "GOLD STANDARD" Label mehr. Rep 1 ist einfach Rep 1.
   */
  static getUserPrompt(set: WorkoutSet): string {
    // 1. Timeline bauen
    let repLog = "";

    for (let i = 0; i < set.heartRates.length; i++) {
      const duration = set.durations[i];
      const hr = set.heartRates[i];

      // Status bestimmen anhand deiner lokalen Berechnung
      let status = "PERFECT";
      if (set.failed && set.failed[i]) {
        status = `FAILURE: ${set.failed[i]}`; // z.B. FAILURE: FORM
      }

      repLog += `Rep ${i + 1}: ${duration}ms | ${hr}bpm | ${status}\n`;
    }

    // 2. Finaler Prompt
    return `
# WORKOUT LOG
Exercise: ${set.name}
Total Reps: ${set.reps}
Perfect Reps: ${set.perfect}

# TIMELINE
${repLog}

# TASK
Give a short, motivating coaching tip based on this timeline (English, max 30 words).
`.trim();
  }
}