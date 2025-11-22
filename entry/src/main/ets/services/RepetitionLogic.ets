import sensor from '@ohos.sensor';
import common from '@ohos.app.ability.common';
import vibrator from '@ohos.vibrator';
import { SensorFrame, SensorBuffer, Vector3, Quaternion } from '../SensorData';
import { FileUtils } from '../services/FileUtils';
import { GraphRendererService } from '../services/GraphRendererService';

// Interface so the Logic can talk to the UI
export interface IRecorderUI {
  onStatusChange(message: string, color: number | string | Color): void; // Accepting Color type or raw value
  onDataUpdate(duration: string, frameCount: number): void;
  onRecordingFinished(data: SensorFrame[]): void;
}

export class RepetitionLogic {
  private ui: IRecorderUI;
  // --- INTERNAL VARIABLES ---
  public isCapturing: boolean = false // True if we are in the active loop
  public isRecording: boolean = false; // True ONLY when actually saving data

  private timerId: number = -1;
  private startTime: number = 0;
  private buffer: SensorBuffer = new SensorBuffer();
  private recordedData: SensorFrame[] = [];
  // --- AUTO-STOP ---
  private startOrientation: Quaternion = new Quaternion(); // Stores inital orientation
  private hasMotionStarted: boolean = false;
  // Counters
  private stabilityCounter: number = 0; // Counts frames of stillness for Auto-Start
  private idleFrameCounter: number = 0; // Counts frames of stillness for Auto-Stop

  // Thresholds
  private readonly GRAVITY_BASELINE: number = 9.8;
  private readonly STABILITY_THRESHOLD: number = 0.5 // Strict stillness for start (m/s^2)
  private readonly STABILITY_FRAMES_NEEDED: number = 20 // ~1 second to trigger start

  private readonly MOTION_START_THRESHOLD: number = 2.0; // m/s^2
  private readonly MOTION_STOP_THRESHOLD: number = 0.8; // m/s^2
  private readonly ANGLE_THRESHOLD_DEG: number = 25.0; // Degrees allowed error from start pos
  private readonly IDLE_TIMEOUT_FRAMES: number = 20; // ~1 second of stillness

  private readonly START_GRACE_PERIOD: number = 300; // Ignore sensor data for this long after start to let vibration die down

  // --- GRAPHING SETUP ---
  //private settings: RenderingContextSettings = new RenderingContextSettings(true);
  //private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D();
  private graphRenderer: GraphRendererService = new GraphRendererService();

  constructor(uiDelegate: IRecorderUI) {
    this.ui = uiDelegate;
  }

  setCanvasContext(context: CanvasRenderingContext2D) {
    this.context = context;
  }

  // --- SENSOR SETUP ---
  initSensors() {
    try {
      sensor.on(sensor.SensorId.ACCELEROMETER, (data) => {
        this.buffer.accelX = data.x;
        this.buffer.accelY = data.y;
        this.buffer.accelZ = data.z;
      }, { interval: 20000000 }); // 20ms

      sensor.on(sensor.SensorId.ROTATION_VECTOR, (data) => {
        this.buffer.quatX = data.x;
        this.buffer.quatY = data.y;
        this.buffer.quatZ = data.z;
        this.buffer.quatW = data.w;
      }, { interval: 20000000 });

    } catch (err) {
      console.error('Sensor init failed: ' + JSON.stringify(err));
    }
  }

  stopSensors() {
    try {
      sensor.off(sensor.SensorId.ACCELEROMETER);
      sensor.off(sensor.SensorId.ROTATION_VECTOR);
    } catch (err) {
      console.error('Sensor stop failed');
    }
  }

  triggerHaptic(duration: number) {
    try {
      vibrator.startVibration({
        type: 'time',
        duration: duration,
      }, {
        id: 0,
        usage: 'physicalFeedback'
      }).catch((error: Error) => {
        console.error('Vibration failed: ' + JSON.stringify(error));
      });
    } catch (err) {
      console.error('Vibration error: ' + JSON.stringify(err));
    }
  }

  // --- RECORDING LOOP ---
  startSession() {
    this.recordedData = [];
    this.graphRenderer.reset(); // Reset graph helper

    // Reset Flags
    this.isRecording = true; // The loop is running
    this.isCapturing = false; // But we aren't saving data yet (waiting for start)
    this.hasMotionStarted = false;
    this.stabilityCounter = 0;
    this.idleFrameCounter = 0;

    // Update UI
    this.ui.onStatusChange("Recording... Move to start!", Color.Yellow);
    this.ui.onDataUpdate("0.00s", 0);

    this.timerId = setInterval(() => {
      this.gameLoop()
    }, 50);
  }

  stopSession(saveData: boolean = true) {
    clearInterval(this.timerId);
    this.isCapturing = false;
    this.isRecording = false;

    // Only save if we actually captured data
    if (saveData && this.recordedData.length > 0) {
      // Success Vibration (Longer double pulse feel)
      this.triggerHaptic(200);
      this.triggerHaptic(200);


      this.ui.onStatusChange("Done", Color.Green);
      this.ui.onRecordingFinished(this.recordedData);
    } else {
      this.ui.onStatusChange("Cancelled (No Data)", Color.Gray);
    }
  }

  /**
   * Save data and watch for end of rep
   */

  processRecordingFrame(accel: Vector3, quat: Quaternion, now: number) {
    let elapsed = now - this.startTime;

    let frame = new SensorFrame()
    frame.timestamp = now;
    frame.elapsed_ms = elapsed;
    frame.accel = accel;
    frame.quaternion = quat;

    this.recordedData.push(frame);

    //UI Updates
    let durationText = (elapsed / 1000).toFixed(2) + "s";
    this.ui.onDataUpdate(durationText, this.recordedData.length);

    // Check if we should stop
    this.checkAutoStop(accel, quat, elapsed);
  }

  // --- MAIN LOOP ---
  gameLoop() {
    let now = new Date().getTime();

    // 1. Prepare current data objects
    let currentAccel = new Vector3(this.buffer.accelX, this.buffer.accelY, this.buffer.accelZ);
    let currentQuat = new Quaternion(this.buffer.quatX, this.buffer.quatY, this.buffer.quatZ, this.buffer.quatW);

    // 2. Update Visuals
    if (this.context) {
      this.graphRenderer.pushValue(currentAccel.y);
      this.graphRenderer.draw(this.context);
    }

    // 3. Are we Waiting to Start? OR Are we Recording?
    if (!this.isCapturing) {
      this.checkAutoStart(currentAccel, currentQuat, now)
    } else {
      this.processRecordingFrame(currentAccel, currentQuat, now)
    }
  }

  /**
   * Wait for user to be still, then trigger start.
   */
  checkAutoStart(accel: Vector3, quat: Quaternion, now: number) {
    let magnitude = accel.getMagnitude();
    let deviation = Math.abs(magnitude - this.GRAVITY_BASELINE);

    // Check if holding still
    if (deviation < this.STABILITY_THRESHOLD) {
      this.stabilityCounter++

      // Debug: Update UI countdown
      let remaining = this.STABILITY_FRAMES_NEEDED - this.stabilityCounter;
      this.ui.onStatusChange(`Hold steady... ${remaining}`, Color.Yellow);

      if (this.stabilityCounter >= this.STABILITY_FRAMES_NEEDED) {
        // --- TRIGGER START ---
        this.isCapturing = true;
        this.startTime = now;

        //Capture the "Zero" orientation
        this.startOrientation = new Quaternion(quat.x, quat.y, quat.z, quat.w);

        this.ui.onStatusChange("GO!", Color.Red);

        // Start Vibration (Short, sharp pulse)
        this.triggerHaptic(200);

      }
    } else {
      // Reset if user moved too much
      this.stabilityCounter = 0;
      this.ui.onStatusChange("Hold still to calibrate...", Color.Yellow);
    }
  }

  /**
   * Analyzes motion energy AND orientation to detect rep completion
   */
  checkAutoStop(accel: Vector3, currentRot: Quaternion, elapsed: number) {
    // GRACE PERIOD: Do not detect any motion start / stop for first time
    // This prevents the start vibration from tricking the app into thinking user moved
    if (elapsed < this.START_GRACE_PERIOD) {
      this.ui.onStatusChange("Get Ready...", Color.Red);
      return;
    } else {
      this.ui.onStatusChange("Ready...", Color.Red);
    }

    // 1. Calculate deviation from gravity (Motion Energy)
    let magnitude = accel.getMagnitude();
    let deviation = Math.abs(magnitude - this.GRAVITY_BASELINE);

    // 2. Calculate Angle Difference (Are we back at start?)
    let angleDiff = this.startOrientation.angleTo(currentRot);

    // 3. State Machine
    if (!this.hasMotionStarted) {
      // Wait for significant movement to begin
      if (deviation > this.MOTION_START_THRESHOLD) {
        this.hasMotionStarted = true;
        this.ui.onStatusChange("Movement Detected!", Color.Red);
      }
    } else {
      // Logic: Motion has started. Now we wait for TWO conditions:
      // A. We are still (low acceleration)
      // B. We are back at the start angle (low angle diff)

      let isStill = deviation < this.MOTION_STOP_THRESHOLD;
      let isBackAtStart = angleDiff < this.ANGLE_THRESHOLD_DEG;

      if (isStill && isBackAtStart) {
        this.idleFrameCounter++;
        this.ui.onStatusChange(`Hold position... ${this.IDLE_TIMEOUT_FRAMES - this.idleFrameCounter}`, Color.Green);

        if (this.idleFrameCounter >= this.IDLE_TIMEOUT_FRAMES) {
          this.stopSession(); // Vibration happens inside stopRecording
        }
      } else {
        this.idleFrameCounter = 0;
        if (!isBackAtStart && isStill) {
          this.ui.onStatusChange(`Return to start... (Off by ${angleDiff.toFixed(0)}°)`, Color.Red);
        } else {
          this.ui.onStatusChange("Recording...", Color.Red);
        }
      }
    }
  }
}