import { CITIES, cityOffsetMinutes } from "./cities.ts";

const SETTINGS_KEY = "royaleSettings";

interface RoyaleSettings {
  SETTING_ENABLE_SECONDS?: number;
  SETTING_DATE_FORMAT?: number;
  SETTING_TIME_ZONE?: number;
}

function readSettings(): RoyaleSettings {
  try {
    const raw = localStorage.getItem(SETTINGS_KEY);
    if (raw) return JSON.parse(raw);
  } catch (e) {
    console.log("Error parsing saved settings:", e);
  }
  return {};
}

function offsetMinutesFor(tzIndex: number, now: Date): number {
  if (tzIndex >= 0 && tzIndex < CITIES.length) {
    return cityOffsetMinutes(CITIES[tzIndex], now);
  }
  // -1 is Local time.
  return -now.getTimezoneOffset();
}

// Comptutes and sends the time zone data to the watch face.
export function sendTimezoneData(): void {
  const settings = readSettings();
  const tzIndex =
    typeof settings.SETTING_TIME_ZONE === "number" ? settings.SETTING_TIME_ZONE : -1;
  const now = new Date();

  const dictionary: Record<string, number> = {
    SettingsEnableSeconds: settings.SETTING_ENABLE_SECONDS ?? 0,
    SettingsDateFormat: settings.SETTING_DATE_FORMAT ?? 0,
    SettingsTimeZone: tzIndex,
    SettingsTimeZoneOffsetMinutes: offsetMinutesFor(tzIndex, now),
  };

  Pebble.sendAppMessage(
    dictionary,
    function () {
      console.log("Sent settings", JSON.stringify(dictionary));
    },
    function (error) {
      console.log("sendAppMessage failed", JSON.stringify(error));
    },
  );
}
