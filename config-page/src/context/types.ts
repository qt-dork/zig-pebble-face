export interface WatchInfo {
  platform: string;
  model: string;
  language: string;
  firmware: {
    major: number;
    minor: number;
  };
}

export interface Capabilities {
  APLITE: boolean;
  BASALT: boolean;
  CHALK: boolean;
  DIORITE: boolean;
  EMERY: boolean;
  FLINT: boolean;
  GABBRO: boolean;
  BW: boolean;
  COLOR: boolean;
  ROUND: boolean;
  RECT: boolean;
  DISPLAY_144x168: boolean;
  DISPLAY_180x180_ROUND: boolean;
  DISPLAY_200x228: boolean;
  DISPLAY_260x260_ROUND: boolean;
  MICROPHONE: boolean;
  SMARTSTRAP: boolean;
  SMARTSTRAP_POWER: boolean;
  HEALTH: boolean;
}

export interface Settings {
  /** Screen update frequency. 0 = per second, 1 = per 15s, 2 = per minute. */
  SETTING_ENABLE_SECONDS: number;
  /** 0 = MM-DD, 1 = DD-MM. */
  SETTING_DATE_FORMAT: number;
  /** Index of the cities list. -1 is local time. */
  SETTING_TIME_ZONE: number;

  // Legacy world-clock settings from Time Traveler.
  // I'm scared to delete stuff. Since things may break.
  SETTING_PINNED_CITIES?: string;
  SETTING_CUSTOM_CITIES?: string;
}
