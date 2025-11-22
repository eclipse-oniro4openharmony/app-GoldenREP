import { Exercise, EXERCISE_DB } from '../models/ExerciseData';

@Component
export struct TrainingView {
  @Prop exercise: Exercise;
  onBack: () => void = () => {};

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
            Text('Record Ghost Rep')
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
        })

      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')

      Circle()
        .width('100%').height('100%')
        .fillOpacity(0).strokeWidth(8).stroke('#1E293B')

      Text('×')
        .fontSize(30).fontColor('#475569')
        .position({ x: '50%', y: 10 }).translate({ x: '-50%' })
        .onClick(this.onBack)
    }
    .width('100%').height('100%')
    .borderRadius('50%')
    .clip(true)
    .backgroundColor('#020617')
  }
}