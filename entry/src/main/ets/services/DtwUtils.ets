/**
 * dtw_utils.ts
 * * A dedicated utility class for performing Dynamic Time Warping (DTW)
 * on sensor data for HarmonyOS / ArkTS.
 * * OPTIMIZED: Includes Sakoe-Chiba Band windowing and corrected Euclidean distance.
 */

export class DTWUtils {

  /**
   * Helper to create an array filled with a specific value.
   */
  private static createFilledArray(size: number, value: number): number[] {
    let arr: number[] = [];
    for (let i = 0; i < size; i++) {
      arr.push(value);
    }
    return arr;
  }

  /**
   * Computes the DTW distance with an optional search window.
   */
  static compute(seriesA: number[], seriesB: number[], window: number = -1): number {
    const n = seriesA.length;
    const m = seriesB.length;

    if (n === 0 || m === 0) return Number.POSITIVE_INFINITY;

    const w = (window === -1) ? Math.max(n, m) : Math.max(window, Math.abs(n - m));

    // 1. Init Matrix safely
    let dtw: number[][] = [];
    for (let i = 0; i <= n; i++) {
      dtw.push(DTWUtils.createFilledArray(m + 1, Number.POSITIVE_INFINITY));
    }
    dtw[0][0] = 0;

    // 2. Compute Path
    for (let i = 1; i <= n; i++) {
      const startJ = Math.max(1, i - w);
      const endJ = Math.min(m, i + w);

      for (let j = startJ; j <= endJ; j++) {
        const cost = Math.abs(seriesA[i - 1] - seriesB[j - 1]);
        dtw[i][j] = cost + Math.min(dtw[i - 1][j], dtw[i][j - 1], dtw[i - 1][j - 1]);
      }
    }
    return dtw[n][m];
  }

  /**
   * Computes Vector DTW with Window Optimization.
   */
  static computeVector(seriesA: number[][], seriesB: number[][], window: number = -1): number {
    const n = seriesA.length;
    const m = seriesB.length;

    if (n === 0 || m === 0) return Number.POSITIVE_INFINITY;

    const w = (window === -1) ? Math.max(n, m) : window;

    let dtw: number[][] = [];
    for (let i = 0; i <= n; i++) {
      dtw.push(DTWUtils.createFilledArray(m + 1, Number.POSITIVE_INFINITY));
    }
    dtw[0][0] = 0;

    for (let i = 1; i <= n; i++) {
      const vecA = seriesA[i - 1];

      const startJ = Math.max(1, i - w);
      const endJ = Math.min(m, i + w);

      for (let j = startJ; j <= endJ; j++) {
        const vecB = seriesB[j - 1];

        let sumSq = 0;
        const dimensions = Math.min(vecA.length, vecB.length);
        for (let k = 0; k < dimensions; k++) {
          sumSq += Math.pow(vecA[k] - vecB[k], 2);
        }

        const cost = Math.sqrt(sumSq);

        dtw[i][j] = cost + Math.min(dtw[i - 1][j], dtw[i][j - 1], dtw[i - 1][j - 1]);
      }
    }

    // Return the accumulated linear distance directly
    return dtw[n][m];
  }

  /**
   * Z-Score Normalization for 1D Array
   */
  static zNormalize(data: number[]): number[] {
    const n = data.length;
    if (n === 0) return [];

    let sum = 0;
    for (let val of data) sum += val;
    const mean = sum / n;

    let sumSqDiff = 0;
    for (let val of data) sumSqDiff += Math.pow(val - mean, 2);
    const stdDev = Math.sqrt(sumSqDiff / n);

    // Prevent divide by zero
    if (stdDev === 0) return DTWUtils.createFilledArray(n, 0);

    return data.map((val) => (val - mean) / stdDev);
  }

  /**
   * Z-Score Normalization for Vector Arrays.
   */
  static zNormalizeVector(data: number[][]): number[][] {
    if (data.length === 0) return [];
    const dimensions = data[0].length;
    const n = data.length;

    // Use safe array creation
    const means = DTWUtils.createFilledArray(dimensions, 0);
    const stdDevs = DTWUtils.createFilledArray(dimensions, 0);

    for (let row of data) {
      for (let k = 0; k < dimensions; k++) {
        means[k] += row[k];
      }
    }
    for (let k = 0; k < dimensions; k++) means[k] /= n;

    for (let row of data) {
      for (let k = 0; k < dimensions; k++) {
        stdDevs[k] += Math.pow(row[k] - means[k], 2);
      }
    }
    for (let k = 0; k < dimensions; k++) {
      stdDevs[k] = Math.sqrt(stdDevs[k] / n);
      if (stdDevs[k] === 0) stdDevs[k] = 1;
    }

    return data.map(row => {
      return row.map((val, k) => (val - means[k]) / stdDevs[k]);
    });
  }

  /**
   * Downsampling Helper (1D)
   */
  static downsample(data: number[], factor: number): number[] {
    if (factor <= 1) return data;
    let result: number[] = [];
    for (let i = 0; i < data.length; i += factor) {
      result.push(data[i]);
    }
    return result;
  }

  /**
   * Downsampling Helper (Vector/3D)
   */
  static downsampleVector(data: number[][], factor: number): number[][] {
    if (factor <= 1) return data;
    let result: number[][] = [];
    for (let i = 0; i < data.length; i += factor) {
      result.push(data[i]);
    }
    return result;
  }
}