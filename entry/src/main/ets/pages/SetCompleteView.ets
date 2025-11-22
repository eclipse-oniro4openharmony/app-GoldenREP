import { SetCompleteData } from '../models/SetCompleteData';
import router from '@ohos.router';

@Entry
@Component
struct SetCompleteView {
  @State setCompleteData: SetCompleteData = {
    reps: 6,
    accuracyPercentage: 92,
    coachFeedback: "Tempo matched the Ghost Rep perfectly. Heart rate stable. Increase weight. This is a significantly longer feedback message to test the scrolling behavior on a small wearable screen. Ensure this text is long enough to exceed the available space.",
  }

  build() {
    Scroll() {
      Column() {
        Text('Set Complete')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ top: 20, bottom: 20 })
          .alignSelf(ItemAlign.Center)

        Row({ space: 12 }) {
          this.StatBox('Reps', this.setCompleteData.reps.toString(), '#282C3A')
          this.StatBox('Accuracy', `${this.setCompleteData.accuracyPercentage}%`, '#282C3A')
        }
        .padding({ bottom: 10 })

        Column() {
          Row({ space: 5 }) {
            Text('✨')
              .fontSize(10)
              .fontColor('#BF90F0')

            Text('COACH')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor('#BF90F0')
          }
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 5 })


          Text(`"${this.setCompleteData.coachFeedback}"`)
            .fontSize(12)
            .fontColor(Color.White)
            .textAlign(TextAlign.Start)
            .margin({ bottom: 15 })

        }
        .width('80%')
        .padding(10)
        .backgroundColor('#3B2B4C')
        .border({
          radius: 12,
          width: 1,
          color: '#BF90F0'
        })

        Button('Finish')
          .alignSelf(ItemAlign.Center)
          .width('30%')
          .height(30)
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('#424765')
          .borderRadius(8)
          .margin({ top: 5, bottom: 5 })
          .onClick(() => {
            router.clear();
            router.pushUrl({ url: 'pages/Index' });
          })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder StatBox(title: string, value: string, backgroundColor: string) {
    Column() {
      Text(title)
        .fontSize(12)
        .fontColor(Color.White)
        .opacity(0.7)
        .margin({ bottom: 5 })

      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
    }
    .width('40%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(backgroundColor)
    .borderRadius(12)
  }
}