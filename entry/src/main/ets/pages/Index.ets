import { Exercise, EXERCISE_DB } from '../models/ExerciseData';
import router from '@ohos.router';

@Entry
@Component
struct Index {
  private swiperController: SwiperController = new SwiperController();
  @State currentIndex: number = 0;

  build() {
    Stack() {
      Swiper(this.swiperController) {
        ForEach(EXERCISE_DB, (item: Exercise) => {
          Column({ space: 5 }) {

            Image(item.image)
              .width(70)
              .height(70)

            Text(item.name)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)

            Text(item.zone)
              .fontSize(12)
              .fontColor('#94A3B8')
              .textAlign(TextAlign.Center)
          }
          .justifyContent(FlexAlign.Start)
          .padding({ top: 35 })
          .width('100%')
          .height('100%')
        })
      }
      .index(this.currentIndex)
      .onChange((index: number) => this.currentIndex = index)
      .displayArrow({
        isSidebarMiddle: true, // Vertically centers the arrows
        backgroundSize: 24,
        arrowSize: 24,
        arrowColor: Color.Blue
      }, false)
      .loop(true)

      Text('SELECT MOVEMENT')
        .fontSize(10)
        .fontColor('#64748B')
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1)
        .position({ x: '50%', y: 25 })
        .translate({ x: '-50%' })

      Button('Select')
        .width(130)
        .height(40)
        .backgroundColor('#2563EB')
        .fontSize(16)
        .position({ x: '50%', y: '85%' })
        .translate({ x: '-50%', y: '-100%' })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/TrainingView',
            params: {
              exercise: EXERCISE_DB[this.currentIndex]
            }
          });
        })

      Circle()
        .width('100%').height('100%')
        .fillOpacity(0).strokeWidth(8).stroke('#1E293B')
        .hitTestBehavior(HitTestMode.None)

    }
    .width('100%').height('100%')
    .borderRadius('50%')
    .clip(true)
    .backgroundColor('#020617')
  }
}