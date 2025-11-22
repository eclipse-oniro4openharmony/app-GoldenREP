import common from '@ohos.app.ability.common';
import { RepetitionLogic, IRecorderUI } from '../services/RepetitionLogic';
import { SensorFrame } from '../SensorData';
import { FileUtils } from '../services/FileUtils';
import { PermissionHelper } from '../services/PermissionHelper';

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
  onRepetitionComplete(){

  }
  onSessionStopped() {
    this.owner.isRecording = false;
  }
}

@Entry
@Component
export struct BaselineView {
  @State isRecording: boolean = false;
  @State statusMessage: string = "Ready to Record Baseline";
  @State statusColor: Color = Color.Gray;
  @State durationText: string = "0.00s";
  @State saveResult: string = "";

  private permission_context = getContext(this) as common.UIAbilityContext;
  private logic: RepetitionLogic | null = null;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  async aboutToAppear() {

    const granted: boolean =  await PermissionHelper.requestHealthPermission(this.permission_context);

    this.logic = new RepetitionLogic(new BaselineDelegate(this));
    this.logic.initSensors();
  }

  aboutToDisappear() {
    this.logic?.stopSensors();
  }

  toggleRec() {
    if (this.isRecording) {
      this.logic?.stopSession();
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
        .fontSize(14).fontWeight(FontWeight.Bold).margin(20)

      Canvas(this.context)
        .width('60%').height(80).backgroundColor('#222')
        .onReady(() => this.logic?.setCanvasContext(this.context))

      Text(this.statusMessage).fontSize(14).fontColor(this.statusColor).margin(10)
      Text(this.durationText).fontSize(14).fontWeight(FontWeight.Bold)

      Button(this.isRecording ? "STOP" : "START BASELINE RECORDING")
        .backgroundColor(this.isRecording ? Color.Red : Color.Blue)
        .width('60%').height(40).margin(20)
        .onClick(() => this.toggleRec())

      Text(this.saveResult).fontSize(12).fontColor(Color.Gray)
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
  }
}