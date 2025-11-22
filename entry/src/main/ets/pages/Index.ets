import common from '@ohos.app.ability.common';
import { SensorFrame } from '../SensorData';
import { FileUtils } from '../services/FileUtils';
import { RepetitionLogic, IRecorderUI } from '../services/RepetitionLogic';

// Define a concrete class to implement the interface.
class RecorderDelegate implements IRecorderUI {
  private owner: RepetitionRecorder;

  constructor(owner: RepetitionRecorder) {
    this.owner = owner;
  }

  onStatusChange(msg: string, color: number | string | Color): void {
    this.owner.statusMessage = msg;
    this.owner.statusColor = color as Color;
  }

  onDataUpdate(duration: string, count: number): void {
    this.owner.durationText = duration;
    this.owner.frameCount = count;
  }

  onRecordingFinished(data: SensorFrame[]): void {
    this.owner.handleSave(data);
    this.owner.isRecording = false;
  }
}

@Entry
@Component
struct RepetitionRecorder {
  // --- STATE VARIABLES ---
  @State isRecording: boolean = false;
  @State durationText: string = "0.00s";
  @State frameCount: number = 0;
  @State saveStatus: string = "";
  @State statusMessage: string = "Ready";
  @State statusColor: Color = Color.Gray;

  // --- LOGIC ENGINE ---
  private logic: RepetitionLogic | null = null;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  aboutToAppear() {
    // 2. Instantiate the Delegate class and pass 'this' (the UI component)
    let uiDelegate = new RecorderDelegate(this);

    this.logic = new RepetitionLogic(uiDelegate);
    this.logic.initSensors();
  }

  aboutToDisappear() {
    this.logic?.stopSensors();
  }

  // Made public so the Delegate class can access it
  public handleSave(data: SensorFrame[]) {
    let context = getContext(this) as common.UIAbilityContext;
    this.saveStatus = FileUtils.saveJson(context, 'rep.json', data);
  }

  toggleRecording() {
    if (this.isRecording) {
      // User clicked Stop/Cancel
      this.logic?.stopSession(false);
      this.isRecording = false;
      this.statusMessage = "Cancelled";
      this.statusColor = Color.Gray;
    } else {
      // User clicked Start
      this.saveStatus = "";
      this.isRecording = true;
      this.logic?.startSession();
    }
  }

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
          .onReady(() => {
            this.logic?.setCanvasContext(this.context);
          })

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

        Button(this.isRecording ? "CANCEL / STOP" : "START SESSION")
          .width('60%')
          .height(40)
          .backgroundColor(this.isRecording ? Color.Red : Color.Blue)
          .fontSize(14)
          .onClick(() => {
            this.toggleRecording();
          })

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