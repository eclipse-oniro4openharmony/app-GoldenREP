export class Vector3 {
  x: number = 0;
  y: number = 0;
  z: number = 0;

  constructor(x: number = 0, y: number = 0, z: number = 0) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  // Helper to calculate vector length (magnitude)
  getMagnitude(): number {
    return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
  }
}

export class Quaternion {
  x: number = 0;
  y: number = 0;
  z: number = 0;
  w: number = 1;

  constructor(x: number = 0, y: number = 0, z: number = 0, w: number = 1) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.w = w;
  }

  // Calculate the angle difference (in degrees) between this and another quaternion
  angleTo(other: Quaternion): number {
    // Dot product calculates similarity
    let dot = this.x * other.x + this.y * other.y + this.z * other.z + this.w * other.w;

    // Clamp dot product to valid range [-1, 1] to prevent NaN errors
    if (dot < -1) dot = -1;
    if (dot > 1) dot = 1;

    // Quaternions represent the same rotation twice (q and -q).
    // We take the absolute value to find the shortest path.
    let angleRad = 2 * Math.acos(Math.abs(dot));

    // Convert Radians to Degrees
    return angleRad * (180 / Math.PI);
  }
}

export class SensorFrame {
  timestamp: number = 0;
  elapsed_ms: number = 0;

  accel: Vector3 = new Vector3();
  quaternion: Quaternion = new Quaternion();
  heartRate: number = 0;
}

export class SensorBuffer {
  accelX: number = 0;
  accelY: number = 0;
  accelZ: number = 0;

  quatX: number = 0;
  quatY: number = 0;
  quatZ: number = 0;
  quatW: number = 1;

  heartRate: number = 0;
}