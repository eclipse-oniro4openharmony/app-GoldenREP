import { RepetitionLogic, IRecorderUI } from '../services/RepetitionLogic';
import { SensorFrame } from '../SensorData';

class WorkoutDelegate implements IRecorderUI {
  private owner: WorkoutView;
  constructor(owner: WorkoutView) { this.owner = owner; }

  onStatusChange(msg: string, color: number | string | Color) {
    this.owner.statusMessage = msg;
    this.owner.statusColor = color as Color;
  }
  onDataUpdate(duration: string, count: number) {
  }
  onRepetitionComplete() {
    // Rep finished!
    this.owner.repCount++;
  }
  onSessionStopped() {
    this.owner.isWorkoutActive = false;
  }
}

@Component
export struct WorkoutView {
  @State isWorkoutActive: boolean = false;
  @State repCount: number = 0;
  @State statusMessage: string = "Ready to Workout";
  @State statusColor: Color = Color.Gray;

  onFinishSet: () => void = () => {};

  private logic: RepetitionLogic | null = null;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  aboutToAppear() {
    this.logic = new RepetitionLogic(new WorkoutDelegate(this));
    this.logic.initSensors();
  }

  aboutToDisappear() {
    this.logic?.stopSensors();
  }

  toggleWorkout() {
    if (this.isWorkoutActive) {
      this.logic?.stopSession();
      // Trigger completion
      this.onFinishSet();
    } else {
      this.repCount = 0; // Reset counter
      // TRUE = Continuous Mode
      this.logic?.startSession(true);
      this.isWorkoutActive = true;
    }
  }

  build() {
    Column() {
      Text("WORKOUT SESSION")
        .fontSize(14).fontWeight(FontWeight.Bold).margin(20)

      // Big Counter
      Text(this.repCount.toString())
        .fontSize(14)
        .fontWeight(FontWeight.Bolder)
        .fontColor(Color.Blue)

      Text("REPS")
        .fontSize(14).fontColor(Color.Gray).margin({bottom: 20})

      Text(this.statusMessage)
        .fontSize(14)
        .fontColor(this.statusColor)
        .textAlign(TextAlign.Center)
        .margin(10)

      // Visualizer (Optional for workout, but looks cool)
      Canvas(this.context)
        .width('30%').height(10).backgroundColor('#111').margin(10)
        .onReady(() => this.logic?.setCanvasContext(this.context))

      Button(this.isWorkoutActive ? "FINISH WORKOUT" : "START SET")
        .backgroundColor(this.isWorkoutActive ? Color.Red : Color.Green)
        .width('30%').height(10).margin(10)
        .onClick(() => this.toggleWorkout())
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
  }
}