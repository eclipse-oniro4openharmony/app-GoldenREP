export enum FailureReason {
  FORM_BAD = 'FORM_BAD',
  TOO_FAST = 'TOO_FAST',
  TOO_SLOW = 'TOO_SLOW',
  TOO_SHORT = 'TOO_SHORT',  // Likely noise/bump
  NO_REFERENCE = 'NO_REFERENCE',
  HEARTRATE_LOW = 'HEARTRATE_LOW',
  HEARTRATE_HIGH = 'HEARTRATE_HIGH',
}


export interface WorkoutSet {
  name: string;
  reps: number;
  perfect: number;
  failed: (FailureReason|undefined)[];
  heartRates: number[];
  durations: number[];
}