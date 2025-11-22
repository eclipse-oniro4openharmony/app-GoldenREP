import { Exercise, EXERCISE_DB } from '../models/ExerciseData';
import { SelectionView } from './SelectionView';
import { TrainingView } from './TrainingView';

@Entry
@Component
struct WatchApp {
  // If null, show SelectionView. If set, show TrainingView.
  @State selectedExercise: Exercise | null = null;

  build() {
    Column() {
      if (this.selectedExercise) {
        TrainingView({
          exercise: this.selectedExercise,
          onBack: () => {
            this.selectedExercise = null;
          }
        })
      } else {
        SelectionView({
          onExerciseSelect: (exercise: Exercise) => {
            this.selectedExercise = exercise;
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}