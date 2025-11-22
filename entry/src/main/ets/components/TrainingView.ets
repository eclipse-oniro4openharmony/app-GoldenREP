import { Exercise } from '../models/ExerciseData';
import router from '@ohos.router';

@Component
export struct TrainingView {
  @Prop exercise: Exercise;
  onBack: () => void = () => {};
  onStartBaseline: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Center }) {

      Column() {

        Text(this.exercise.name)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .margin({ bottom: 4 })

        Text('Sensor Fusion Ready')
          .fontSize(12)
          .fontColor('#94A3B8')
          .margin({ bottom: 20 })

        Button() {
          Row({ space: 4 }) {
            Text('Start recording')
              .fontSize(14)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium)
          }
        }
        .type(ButtonType.Capsule)
        .backgroundColor('#1E293B')
        .width('85%')
        .height(48)
        .onClick(() => {
          console.info("Recording started for " + this.exercise.name);
          this.onStartBaseline(); // Trigger navigation
        })

      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')

      Circle()
        .width('100%')
        .height('100%')
        .fillOpacity(0)
        .strokeWidth(8)
        .stroke('#1E293B')
        // CRITICAL FIX: Allow clicks to pass through this overlay
        .hitTestBehavior(HitTestMode.None)

      Text('×')
        .fontSize(30)
        .fontColor('#475569')
        .position({ x: '50%', y: 10 })
        .translate({ x: '-50%' })
        .onClick(this.onBack)
    }
    .width('100%').height('100%')
    .borderRadius('50%')
    .clip(true)
    .backgroundColor('#020617')
  }
}