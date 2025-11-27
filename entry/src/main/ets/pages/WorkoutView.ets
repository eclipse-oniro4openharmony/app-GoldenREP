import { RepetitionLogic, IRecorderUI } from '../services/RepetitionLogic';
import router from '@ohos.router';
import { common } from '@kit.AbilityKit';
import { RepResult } from '../services/SensorDataParser';
import { FailureReason } from '../models/WorkoutModels'
import { AudioPlayer } from '../services/AudioPlayer';

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
  onRepetitionResult(repResult: RepResult): void {
    this.owner.lastRepPerformance = repResult.isSuccessful;
    this.owner.failureReason = repResult.failureReason;
    this.owner.score = repResult.score;
    this.owner.playSound(repResult.failureReason);
  }
}

@Entry
@Component
struct WorkoutView {
  @State isWorkoutActive: boolean = false;
  @State repCount: number = 0;
  @State statusMessage: string = "Ready to Workout?";
  @State statusColor: Color = Color.Gray;
  @State showConfetti: boolean = false;
  @State confettiText: string = "🎉";
  @State backgroundBlur: number = 0; // Add blur state
  @State lastRepPerformance: boolean | undefined = undefined;
  @State failureReason: FailureReason | undefined = undefined;
  @State score: number = 0;

  onFinishSet: () => void = () => {};

  playSound: (failureReason: FailureReason | undefined) => Promise<void> = async (failureReason) => {
    let filenamePrefix: string;
    if(failureReason){
      filenamePrefix = failureReason.toString()
    } else {
      filenamePrefix = 'FORM_GOOD'
    }
    const audioIndex = Math.floor(Math.random() * 2);
    const context = getContext(this) as common.UIAbilityContext;
    //await this.audioPlayer.loadRawAudio(context, 'HEARTRATE_HIGH_0.mp3');
    await this.audioPlayer.loadRawAudio(context, `${filenamePrefix}_${audioIndex}.mp3`);
    this.audioPlayer.play();
  }

  private logic: RepetitionLogic | null = null;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private audioPlayer: AudioPlayer = new AudioPlayer();

  async aboutToAppear(): Promise<void> {
    this.logic = new RepetitionLogic(new WorkoutDelegate(this));
    this.logic.initSensors();
    await this.audioPlayer.init();
  }

  aboutToDisappear(): void {
    this.logic?.stopSensors();
    this.audioPlayer.release();
  }

  launchConfetti(): void {
    this.showConfetti = true;

    // Animate blur background
    animateTo({
      duration: 300,
      curve: Curve.EaseOut
    }, () => {
      this.backgroundBlur = 10; // Apply blur
    });

    // Simple confetti effect with emoji animation
    let counter = 0;
    const confettiEmojis = ["✨"];

    const animateEmoji = () => {
      if (counter < 10) { // Animate for 10 cycles
        this.confettiText = confettiEmojis[counter % confettiEmojis.length];
        counter++;
        setTimeout(animateEmoji, 200);
      } else {
        // Remove blur when animation ends
        animateTo({
          duration: 200,
          curve: Curve.EaseIn
        }, () => {
          this.backgroundBlur = 0;
        });
        this.showConfetti = false;
      }
    };

    animateEmoji();
  }

  toggleWorkout(): void {
    if (this.isWorkoutActive) {
      this.logic?.stopSession();
      this.launchConfetti();
      setTimeout(() => {
        router.pushUrl({ url: 'pages/SetCompleteView' });
      }, 2000);
    } else {
      this.repCount = 0;
      this.logic?.startSession(true);
      this.isWorkoutActive = true;
    }
  }

  build() {
    Stack() {
      // Main content with blur effect
      Column() {
        Text("WORKOUT SESSION")
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .margin(20)

        Text(this.repCount.toString())
          .fontSize(18)
          .fontWeight(FontWeight.Bolder)
          .fontColor('#2563EB')

        Text("REPS")
          .fontSize(14)
          .fontColor(Color.Gray)
          .margin({ bottom: 20 })

        Text(this.lastRepPerformance === undefined
          ? undefined
          : (this.lastRepPerformance ? "success" : "not success")
        )
        Text(this.score.toString())
        Text(this.failureReason ? this.failureReason.toString() : '')
        Text(this.statusMessage)
          .fontSize(14)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)

        Canvas(this.context)
          .width('30%')
          .height(10)
          .margin(5)
          .onReady(() => {
            this.logic?.setCanvasContext(this.context);
          })

        Button(this.isWorkoutActive ? "FINISH WORKOUT" : "START SET")
          .backgroundColor('#2563EB')
          .width('40%')
          .height(30)
          .onClick(() => {
            this.toggleWorkout();
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor(Color.Black)
      .blur(this.backgroundBlur) // Apply blur to main content

      // Confetti Overlay
      if (this.showConfetti) {
        Column() {
          Text(this.confettiText)
            .fontSize(50)
            .fontColor(Color.Yellow)

          Text("Workout Complete!")
            .fontSize(18)
            .fontColor(Color.White)
            .margin({ top: 20 })
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#00000080') // Semi-transparent overlay
      }
    }
    .width('100%')
    .height('100%')
  }
}
