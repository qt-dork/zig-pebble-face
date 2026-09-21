import { clearCachedPinnedCities, forceResend, sendCityData } from "./city-data.ts";

const configDataUri = 'http://localhost:3000/royale/';

let dstCheckTimer: number | null = null;
let locationAvailable: boolean | null = null;

function startDstChecks() {
  if (dstCheckTimer) clearInterval(dstCheckTimer);
  dstCheckTimer = setInterval(function () {
    sendCityData(null, locationAvailable);
  }, 30 * 60 * 1000);
}

Pebble.addEventListener("ready", function () {
  startDstChecks();

  sendCityData(null, locationAvailable);

  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(function (pos) {
      locationAvailable = true;
      sendCityData(pos.coords, locationAvailable);
    }, function () {
      locationAvailable = false;
      sendCityData(null, locationAvailable);
    }, {
      enableHighAccuracy: false,
      timeout: 5000,
      maximumAge: 600000
    });
  } else {
    locationAvailable = false;
    sendCityData(null, locationAvailable);
  }
});

Pebble.addEventListener("appmessage", function (event) {
  const payload = event.payload || {};

  if (payload.REQUEST_CITY_DATA) {
    forceResend();
    sendCityData(null, locationAvailable);
    return;
  }
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

  // Clear cached city list and send fresh data to watch
  clearCachedPinnedCities();
  forceResend();
  sendCityData(null, locationAvailable);
});
