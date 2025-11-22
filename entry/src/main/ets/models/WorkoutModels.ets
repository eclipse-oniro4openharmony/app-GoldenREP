export enum ReasonFailure {
  SLOW = "SLOW",
  HEARTRATE = "HEARTRATE",
  SPEED = "SPEED",
  FAST = "FAST",
  JITTER = "JITTER",
  FORM = "FORM"
}

export interface  WorkoutSet {
  name: string;
  reps: number;
  perfect: number;
  failed: (ReasonFailure|undefined)[];
  heartRates: number[];
  durations: number[];
}