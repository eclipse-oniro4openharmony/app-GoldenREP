# GoldenRep

<p align="center">
  <strong>🥉 3rd Place — Huawei Track @ HackaTUM 2025</strong>
</p>

<p align="center">
<img width="250" height="250" alt="image" src="https://github.com/user-attachments/assets/651984e3-d89d-4a8f-8dc2-6186d0c77581" />
</p>

We’ve all been there: you’re at the gym, trying to push your limits, but as you get tired, your form slips. Bad form doesn't just mean fewer gains; it leads to injuries. Personal trainers are great, but they are expensive and can't be with you for every single rep.

We wanted to digitize the experience of having a pro trainer who knows exactly how you move. We were inspired to build Golden Rep, a solution that captures your perfect movement when you are fresh and uses it as the "Gold Standard" to guide you through the rest of your workout.

## What it does
Golden Rep is a HarmonyOS wearable application designed for Huawei smartwatches that acts as an intelligent, real-time AI weightlifting coach.
- **The "Golden Rep" Baseline**: The user records one perfect repetition (the "Golden Rep"). The app records the precise tempo, rotation, and acceleration of this movement via the sensors of the Huawei watch.
- **Intelligent Monitoring**: During your set, the watch compares every subsequent rep against that Golden Rep in real-time using Sensor Fusion (Accelerometer, Rotation Vector, and Heart Rate).
- **Real-Time Feedback**: It provides instant auditory motivational feedback if you are moving too fast, too slow, breaking form, or your heart rate is too high. (e.g., "Form is slipping, stay focused" or "Pick up the pace a little").
- **Zero-Touch Interface**: During training, your hands are busy holding weights. The app uses motion thresholds to automatically detect when you are holding still to calibrate, when you start moving, and when a repetition is complete, without requiring you to touch the screen.
- **AI Coaching Insights**: While the watch locally detects deviations from your "Golden Rep", an integrated LLM analyzes the trend of these failures (e.g., spotting fatigue vs. instability) to provide one actionable, human-like tip for your next set.

## How we built it
GoldenRep combines Huawei watch sensors, on-device logic, and cloud-based AI to deliver real-time feedback with minimal latency.
- **Sensor Fusion**: We utilized the @ohos.sensor API to pull high-frequency data (20ms intervals) from the Accelerometer and Rotation Vector sensors, along with Heart Rate monitoring.
- **Haptics**: We used @ohos.vibrator to give physical cues like a short pulse for "Start" and a longer vibration for "Success", so the user doesn't have to look at their wrist while lifting.- 
- **Hybrid AI Architecture**: We implemented a hybrid approach where critical feedback (rep counting, form checks) happens locally on the watch using ArkTS for zero-latency, while complex pattern recognition is offloaded to an LLM via REST API to generate natural language coaching tips.

## Config
To use the ai coach we use the open ai api endpoint. You can add the api key to the AppConfig file in entry/src/main/ets/config.

```
OPEN_AI_API_KEY=<your Open AI API key>
```

## Demo
Click here to watch the demo.

[![Watch the demo](https://github.com/user-attachments/assets/004157d7-b627-4039-8f63-2952d0665baa)](https://youtu.be/kBMS_RdcD9M)
