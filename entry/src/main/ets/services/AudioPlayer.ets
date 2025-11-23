import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class AudioPlayer {
  private avPlayer: media.AVPlayer | undefined = undefined;

  async init() {
    try {
      this.avPlayer = await media.createAVPlayer();
      // We don't need the complex state machine callback for this simple use case anymore
      // unless you use it for UI updates.
      this.avPlayer.on('error', (err: BusinessError) => {
        console.error(`AudioPlayer Error: ${err.message}`);
      });
    } catch (error) {
      console.error(`Failed to create AVPlayer: ${error}`);
    }
  }

  // Updated: Returns a Promise that resolves ONLY when 'prepared'
  async loadRawAudio(context: common.UIAbilityContext, filename: string): Promise<void> {
    if (!this.avPlayer) return;

    // 1. Reset first to ensure we are in a clean state from previous plays
    await this.avPlayer.reset();

    return new Promise(async (resolve, reject) => {
      if (!this.avPlayer) return reject("No Player");

      // 2. Setup a one-time listener for the 'prepared' state
      const stateChangeCallback = (state: media.AVPlayerState) => {
        if (state === 'initialized') {
          this.avPlayer?.prepare();
        }
        if (state === 'prepared') {
          // We are ready to play! Remove listener and resolve.
          this.avPlayer?.off('stateChange');
          resolve();
        }
      };

      this.avPlayer.on('stateChange', stateChangeCallback);

      try {
        const fileDescriptor = await context.resourceManager.getRawFd(filename);
        // 3. Setting this triggers 'initialized' -> which triggers 'prepare' above
        this.avPlayer.fdSrc = {
          fd: fileDescriptor.fd,
          offset: fileDescriptor.offset,
          length: fileDescriptor.length
        };
      } catch (error) {
        this.avPlayer?.off('stateChange'); // clean up
        reject(error);
      }
    });
  }

  play() {
    // We can be less defensive here because loadRawAudio ensures we are prepared
    this.avPlayer?.play();
  }

  release() {
    this.avPlayer?.release();
  }

  reset() {
    this.avPlayer?.reset();
  }
}