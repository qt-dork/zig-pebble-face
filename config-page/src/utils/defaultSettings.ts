import { Settings, Capabilities } from '../context/types';

export const getDefaultSettings = (_capabilities: Capabilities): Settings => ({
  SETTING_ENABLE_SECONDS: 0,
  SETTING_DATE_FORMAT: 0,
  // -1 = local time.
  SETTING_TIME_ZONE: -1,
});
