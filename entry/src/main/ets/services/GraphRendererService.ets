export class GraphRendererService {
  private graphData: number[] = [];
  private readonly MAX_POINTS: number = 50;
  private readonly WIDTH: number = 200;
  private readonly HEIGHT: number = 60;


  /**
   * Adds a new value to the buffer and returns the updated array size (optional use)
   */
  pushValue(value: number) {
    this.graphData.push(value);
    if (this.graphData.length > this.MAX_POINTS) {
      this.graphData.shift();
    }
  }

  /**
   * Resets the graph data
   */
  reset() {
    this.graphData = [];
  }

  /**
   * Draws the current buffer onto the provided context
   */
  draw(context: CanvasRenderingContext2D) {
    // Clear background
    context.clearRect(0, 0, this.WIDTH, this.HEIGHT);

    // Draw Center Line
    context.beginPath();
    context.lineWidth = 1;
    context.strokeStyle = '#333333';
    context.moveTo(0, this.HEIGHT / 2);
    context.lineTo(this.WIDTH, this.HEIGHT / 2);
    context.stroke();

    // Draw Data Line
    context.beginPath();
    context.lineWidth = 2;
    context.strokeStyle = '#00FF00';

    for (let i = 0; i < this.graphData.length; i++) {
      let val = this.graphData[i];

      // Normalization logic: Map range [-25, 25] roughly to height
      let normalized = (val + 5) / 30;

      let y = this.HEIGHT - (normalized * this.HEIGHT);
      let x = (i / this.MAX_POINTS) * this.WIDTH;

      if (i === 0) {
        context.moveTo(x, y);
      } else {
        context.lineTo(x, y);
      }
    }
    context.stroke();
  }
}