import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';

export class FileUtils {
  /**
   * Saves data object to the app's private files directory.
   * @param context The UIAbilityContext to get the filesDir
   * @param filename The name of the file (e.g., 'ghost_rep.json')
   * @param data The object or array to save
   * @returns A success or error message string
   */
  static saveJson(context: common.UIAbilityContext, filename: string, data: object): string {
    try {
      // 1. Get Path
      let filesDir = context.filesDir;
      let filePath = filesDir + '/' + filename;

      // 2. Convert Data
      let jsonString = JSON.stringify(data);

      // 3. Open/Create (Truncate to overwrite)
      //let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      let file = fs.openSync(filePath, fs.OpenMode.APPEND | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);

      // 4. Write
      fs.writeSync(file.fd, jsonString);

      // 5. Close
      fs.closeSync(file);

      console.info("FileUtils: Saved to " + filePath);
      return "Saved to: " + filename;

    } catch (err) {
      console.error("FileUtils: Failed to save - " + JSON.stringify(err));
      return "Save Failed!";
    }
  }
}