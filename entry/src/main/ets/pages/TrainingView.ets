import { Exercise } from '../models/ExerciseData';
import router from '@ohos.router';

interface RouterParams {
  exercise: Exercise;
}

@Entry
@Component
struct TrainingView {
  @State exercise: Exercise = {
    id: 'placeholder',
    name: 'Loading Exercise...',
    zone: 'Unknown',
    image: $r('app.media.shoulderPress'),
  };

  onPageShow() {
    let params = router.getParams();

    // 2. Safely check if parameters were received
    if (params) {
      let routerParams = params as RouterParams;

      this.exercise = routerParams.exercise;

      console.info('TrainingView: Successfully loaded exercise: ' + this.exercise.name);
    }
  }

  onBack: () => void = () => {
    console.info("TrainingView: Back navigation triggered.");
    router.back(); // Use router.back() to return to the previous page (Index)
  };

  onStartBaseline: () => void = () => {
    console.info("TrainingView: Baseline recording started for " + this.exercise.name);
    // Add logic for starting the recording here
  };

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
            Text('Record Golden Rep')
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
          console.info("Starting Baseline recording for " + this.exercise.name);
          router.pushUrl({
            url: 'pages/BaselineView',
            params: {
              exercise: this.exercise,
              // *** NEW: Pass a flag to auto-start recording ***
              startRecording: true
            }
          });
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