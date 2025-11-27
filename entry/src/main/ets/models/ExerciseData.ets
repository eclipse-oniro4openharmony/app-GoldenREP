export interface Exercise {
  id: string;
  name: string;
  zone: string;
  image: Resource;
}

export const EXERCISE_DB: Exercise[] = [
  { id: 'bicep_curl', name: 'Bicep Curl', zone: 'Arms', image: $r('app.media.curlBicep') },
  { id: 'shoulder_press', name: 'Shoulder Press', zone: 'Shoulders', image: $r('app.media.shoulderPress') },
  { id: 'lat_raise', name: 'Lateral Raise', zone: 'Shoulders', image: $r("app.media.lateralRaise") },
  { id: 'squat', name: 'Air Squat', zone: 'Legs', image: $r('app.media.squat') },
];