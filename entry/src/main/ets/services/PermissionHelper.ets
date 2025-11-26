import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';

/**
 * Utility class to handle dynamic runtime permission requests for health data.
 */
export class PermissionHelper {

  // The specific permission string needed for Heart Rate access via the sensor API.
  private static readonly HEALTH_PERMISSION: Permissions = 'ohos.permission.READ_HEALTH_DATA';

  /**
   * Checks the status of and, if necessary, requests the Health Data permission.
   * * @param context The UIAbilityContext required for access control and dialog display.
   * @returns A Promise that resolves to true if permission is granted or already active, false otherwise.
   */
  public static async requestHealthPermission(context: common.UIAbilityContext): Promise<boolean> {

    if (!context) {
      console.error('PermissionHelper: UIAbilityContext is null.');
      return false;
    }

    const atManager = abilityAccessCtrl.createAtManager();

    try {
      // 1. Check if permission is already granted to avoid unnecessary popups
      const grantStatus: abilityAccessCtrl.GrantStatus = await atManager.checkAccessToken(
        context.applicationInfo.accessTokenId,
        PermissionHelper.HEALTH_PERMISSION
      );

      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        console.info('PermissionHelper: Health permission already granted.');
        return true;
      }

      // 2. Request permission from the user (this shows the system dialog)
      console.info('PermissionHelper: Requesting permission...');
      const permissions: Array<Permissions> = [PermissionHelper.HEALTH_PERMISSION];

      const result = await atManager.requestPermissionsFromUser(
        context,
        permissions
      );

      // 3. Check the result
      if (result.authResults.length > 0 && result.authResults[0] === 0) {
        console.info('PermissionHelper: Health permission granted by user.');
        return true;
      } else {
        console.warn('PermissionHelper: Health permission denied by user.');
        return false;
      }

    } catch (err) {
      const error = err as BusinessError;
      console.error(`PermissionHelper: Request failed. Code: ${error.code}, Message: ${error.message}`);
      return false;
    }
  }
}