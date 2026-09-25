import { sendTimezoneData } from "./timezone-data.ts";

const configDataUri = 'http://localhost:3000/royale/';
const DST_CHECK_INTERVAL_MS = 30 * 60 * 1000;

let dstCheckTimer: number | null = null;

// Checks every 30 minutes if it's DST.
function startDstChecks() {
  if (dstCheckTimer) clearInterval(dstCheckTimer);
  dstCheckTimer = setInterval(function () {
    sendTimezoneData();
  }, DST_CHECK_INTERVAL_MS);
}

Pebble.addEventListener("ready", function () {
  startDstChecks();
  sendTimezoneData();
});

// ---- Configuration ----

Pebble.addEventListener('showConfiguration', function () {
  let url = configDataUri;

  const watchInfo = Pebble.getActiveWatchInfo();
  url += (url.indexOf('?') === -1 ? '?' : '&') + 'watchInfo=' + encodeURIComponent(JSON.stringify({
    platform: watchInfo.platform,
    model: watchInfo.model,
    language: watchInfo.language,
    firmware: {
      major: watchInfo.firmware.major,
      minor: watchInfo.firmware.minor
    }
  }));

  const persistedSettings = localStorage.getItem('royaleSettings');
  if (persistedSettings) {
    try {
      const settings = JSON.parse(persistedSettings);
      url += '&settings=' + encodeURIComponent(JSON.stringify(settings));
    } catch (e) {
      console.log('Error loading persisted settings:', e);
    }
  }

  Pebble.openURL(url);
});

Pebble.addEventListener('webviewclosed', function (e) {
  if (!e.response || e.response === 'CANCELLED' || e.response === 'null' || e.response === '{}') {
    return;
  }

  let configData;
  try {
    configData = JSON.parse(decodeURIComponent(e.response));
  } catch (err) {
    console.log('Error parsing configuration response: ' + err);
    try {
      configData = JSON.parse(e.response);
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    } catch (err2) {
      console.log('Failed to parse config data even without decoding');
      return;
    }
  }

  if (configData.return_to) {
    delete configData.return_to;
  }

  // Save to localStorage for persistence
  localStorage.setItem('royaleSettings', JSON.stringify(configData));

  // Push the new settings and time zone offset to the watch
  sendTimezoneData();
});
