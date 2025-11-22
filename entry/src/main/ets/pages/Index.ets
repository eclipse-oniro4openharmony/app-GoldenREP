import sensor from '@ohos.sensor';
import common from '@ohos.app.ability.common';
import vibrator from '@ohos.vibrator';
import { SensorFrame, SensorBuffer, Vector3, Quaternion } from '../SensorData';
import { FileUtils } from '../services/FileUtils';
import { GraphRendererService } from '../services/GraphRendererService';

@Entry
@Component
struct RepetitionRecorder {
  // --- STATE VARIABLES ---
  @State isCapturing: boolean = false // True if we are in the active loop
  @State isRecording: boolean = false; // True ONLY when actually saving data
  @State durationText: string = "0.00s";
  @State frameCount: number = 0;
  @State saveStatus: string = "";
  @State statusMessage: string = "Ready";
  @State statusColor: Color = Color.Gray;

  // --- INTERNAL VARIABLES ---
  private timerId: number = -1;
  private startTime: number = 0;

  private buffer: SensorBuffer = new SensorBuffer();
  private recordedData: SensorFrame[] = [];

  // --- AUTO-STOP
  private startOrientation : Quaternion = new Quaternion(); // Stores inital orientation
  private hasMotionStarted : boolean = false;

  // Counters
  private stabilityCounter : number = 0; // Counts frames of stillness for Auto-Start
  private idleFrameCounter : number = 0; // Counts frames of stillness for Auto-Stop

  // Thresholds
  private readonly GRAVITY_BASELINE: number = 9.8;
  private readonly STABILITY_THRESHOLD: number = 0.5 // Strict stillness for start (m/s^2)
  private readonly STABILITY_FRAMES_NEEDED: number = 20 // ~1 second to trigger start

  private readonly MOTION_START_THRESHOLD: number = 2.0; // m/s^2
  private readonly MOTION_STOP_THRESHOLD: number = 0.8;  // m/s^2
  private readonly ANGLE_THRESHOLD_DEG: number = 25.0;   // Degrees allowed error from start pos
  private readonly IDLE_TIMEOUT_FRAMES: number = 20;     // ~1 second of stillness

  private readonly START_GRACE_PERIOD: number = 1000; // Ignore sensor data for this long after start to let vibration die down

  // --- GRAPHING SETUP ---
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private graphRenderer: GraphRendererService = new GraphRendererService();

  aboutToAppear() {
    this.initSensors();
  }

  aboutToDisappear() {
    this.stopSensors();
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
  pressRecordButton() {
    this.recordedData = [];
    this.graphRenderer.reset(); // Reset graph helper

    // Reset Flags
    this.isRecording = true; // The loop is running
    this.isCapturing = false; // But we aren't saving data yet (waiting for start)
    this.hasMotionStarted = false;
    this.stabilityCounter = 0;
    this.idleFrameCounter = 0;

    this.saveStatus = "";
    this.statusColor = Color.Yellow // Yellow = Waiting for start
    this.statusMessage = "Recording... Move to start!";

    this.timerId = setInterval(() => {
      this.gameLoop()
    }, 50);
  }

  stopRecording() {
    clearInterval(this.timerId);
    this.isCapturing = false;
    this.isRecording = false;
    this.statusColor = Color.Green;
    this.statusMessage = "Done";

    // Only save if we actually captured data
    if (this.recordedData.length > 0) {
      // Success Vibration (Longer double pulse feel)
      this.triggerHaptic(200);
      this.triggerHaptic(200);


      let context = getContext(this) as common.UIAbilityContext;
      this.saveStatus = FileUtils.saveJson(context, 'rep.json', this.recordedData)
    } else {
      this.statusMessage = "Cancelled (No Data)";
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
    this.durationText = (elapsed / 1000).toFixed(2) + "s";
    this.frameCount = this.recordedData.length;

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
    this.graphRenderer.pushValue(currentAccel.y);
    this.graphRenderer.draw(this.context);

    // 3. Are we Waiting to Start? OR Are we Recording?
    if(!this.isCapturing) {
      this.checkAutoStart(currentAccel, currentQuat, now)
    } else  {
      this.processRecordingFrame(currentAccel, currentQuat, now)
    }
  }

  /**
   * Wait for user to be still, then trigger start.
   */
  checkAutoStart(accel: Vector3, quat: Quaternion, now: number){
    let magnitude = accel.getMagnitude();
    let deviation = Math.abs(magnitude - this.GRAVITY_BASELINE);

    // Check if holding still
    if(deviation < this.STABILITY_THRESHOLD) {
      this.stabilityCounter++

      // Debug: Update UI countdown
      let remaining = this.STABILITY_FRAMES_NEEDED - this.stabilityCounter;
      this.statusMessage = `Hold steady... ${remaining}`;

      if (this.stabilityCounter >= this.STABILITY_FRAMES_NEEDED) {
        // --- TRIGGER START ---
        this.isCapturing = true;
        this.startTime = now;

        //Capture the "Zero" orientation
        this.startOrientation = new Quaternion(quat.x, quat.y, quat.z, quat.w);

        this.statusColor = Color.Red;
        this.statusMessage = "GO!"

        // Start Vibration (Short, sharp pulse)
        // this.triggerHaptic(200);

      }
    } else {
        // Reset if user moved too much
        this.stabilityCounter = 0;
        this.statusMessage = "Hold still to calibrate...";
      }
    }

  /**
   * Analyzes motion energy AND orientation to detect rep completion
   */
  checkAutoStop(accel: Vector3, currentRot: Quaternion, elapsed: number) {
    // GRACE PERIOD: Do not detect any motion start / stop for first time
    // This prevents the start vibration from tricking the app into thinking user moved
    if (elapsed < this.START_GRACE_PERIOD) {
      this.statusMessage = "Get Ready...";
      return;
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
        this.statusMessage = "Movement Detected!";
      }
    } else {
      // Logic: Motion has started. Now we wait for TWO conditions:
      // A. We are still (low acceleration)
      // B. We are back at the start angle (low angle diff)

      let isStill = deviation < this.MOTION_STOP_THRESHOLD;
      let isBackAtStart = angleDiff < this.ANGLE_THRESHOLD_DEG;

      if (isStill && isBackAtStart) {
        this.idleFrameCounter++;
        this.statusMessage = `Hold position... ${this.IDLE_TIMEOUT_FRAMES - this.idleFrameCounter}`;

        if (this.idleFrameCounter >= this.IDLE_TIMEOUT_FRAMES) {
          this.statusMessage = "Rep Complete!";
          this.stopRecording(); // Vibration happens inside stopRecording
        }
      } else {
        this.idleFrameCounter = 0;
        if (!isBackAtStart && isStill) {
          this.statusMessage = `Return to start... (Off by ${angleDiff.toFixed(0)}°)`;
        } else {
          this.statusMessage = "Recording...";
        }
      }
    }
  }

  // --- UI BUILD ---
  build() {
    Stack() {
      Rect().width('100%').height('100%').fill(Color.Black)

      Column() {
        Text("GHOST REC")
          .fontColor(Color.Blue)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 5 })

        Canvas(this.context)
          .width(200)
          .height(60)
          .backgroundColor('#111111')
          .margin({ bottom: 10 })
          .onReady(() => { })

        Text(this.durationText)
          .fontColor(Color.White)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 2 })

        // Feedback Text
        Text(this.statusMessage)
          .fontColor(this.statusColor)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 5 })

        Text(`Frames: ${this.frameCount}`)
          .fontColor(Color.Gray)
          .fontSize(10)
          .margin({ bottom: 10 })

        if (!this.isRecording) {
          Button("START SESSION")
            .width('60%')
            .height(40)
            .backgroundColor(Color.Blue)
            .fontSize(14)
            .onClick(() => { this.pressRecordButton(); })
        } else {
          Button("CANCEL / STOP")
            .width('60%')
            .height(40)
            .backgroundColor(Color.Red)
            .fontSize(14)
            .onClick(() => { this.stopRecording(); })
        }

        if (this.saveStatus !== "") {
          Text(this.saveStatus)
            .fontColor(Color.Yellow)
            .fontSize(10)
            .margin({top: 10})
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
  }
}