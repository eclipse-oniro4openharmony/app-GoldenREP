import { RepetitionLogic, IRecorderUI } from '../services/RepetitionLogic';
import router from '@ohos.router';
import { Exercise } from '../models/ExerciseData'; // Import Exercise for type safety
import { RepResult } from '../services/SensorDataParser';

// Define the interface for the router parameters expected by this view
interface BaselineRouterParams {
  exercise: Exercise;
  startRecording?: boolean; // The optional flag passed from TrainingView
}

class BaselineDelegate implements IRecorderUI {
  private owner: BaselineView;
  constructor(owner: BaselineView) { this.owner = owner; }

  onStatusChange(msg: string, color: number | string | Color) {
    this.owner.statusMessage = msg;
    this.owner.statusColor = color as Color;
  }
  onDataUpdate(duration: string, count: number) {
    this.owner.durationText = duration;
  }
  onRepetitionComplete() {

  }
  onSessionStopped() {
    this.owner.isRecording = false;
  }
  onRepetitionResult(repResult: RepResult): void {
    this.owner.calibrationResult = repResult.isSuccessful.toString();
  }
}

@Entry
@Component
struct BaselineView {
  @State isRecording: boolean = false;
  @State statusMessage: string = "Ready to Record Baseline";
  @State statusColor: Color = Color.Gray;
  @State durationText: string = "0.00s";
  @State saveResult: string = "";
  @State calibrationResult: string = "";
  @State exerciseName: string = "";

  private logic: RepetitionLogic | null = null;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  aboutToAppear() {
    // 1. Initialize logic and sensors
    this.logic = new RepetitionLogic(new BaselineDelegate(this));
    this.logic.initSensors();

    let params = router.getParams();
    let routerParams: BaselineRouterParams | null = null;

    if (params) {
      routerParams = params as BaselineRouterParams;
      this.exerciseName = routerParams.exercise.name;
      this.logic.setExerciseName(this.exerciseName);
    }

    // Now ArkTS knows about the startRecording property
    // Check if the parameter exists and is explicitly set to true
    const startImmediately = routerParams && routerParams.startRecording === true;

    if (startImmediately) {
      console.info('BaselineView: Auto-starting recording session.');
      // Call the toggleRec function to start the recording immediately
      // This will set isRecording to true and update the UI
      this.toggleRec();

    }
  }

  aboutToDisappear() {
    this.logic?.stopSensors();
  }

  toggleRec() {
    if (this.isRecording) {
      this.logic?.stopSession();
      // Assume complete when stopping manually
      router.pushUrl({ url: 'pages/WorkoutView' });
    } else {
      this.saveResult = "";
      // FALSE = Single Rep Mode
      this.logic?.startSession(false);
      this.isRecording = true;
    }
  }

  build() {
    Column() {
      Text("CREATE BASELINE")
        .fontSize(14).fontWeight(FontWeight.Bold).margin(15)

        Canvas(this.context)
          .width('60%').height(80)
          .onReady(() => this.logic?.setCanvasContext(this.context))

      Text(this.statusMessage).fontSize(14).fontColor(this.statusColor).padding({bottom : 3})
      Text(this.durationText).fontSize(14).fontWeight(FontWeight.Bold)

      // This button still offers manual control if navigation didn't auto-start
      Button(this.isRecording ? "STOP" : "START BASELINE RECORDING")
        .fontColor(this.isRecording ? Color.White : '#94A3B8')
        .width('30%').height(25)
        .onClick(() => this.toggleRec())
      Text(this.saveResult).fontSize(12).fontColor(Color.Gray)
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
  }
}