import {CITIES, cityOffsetMinutes, dayLabelForCity} from "./cities.ts";
import { FULL_NIGHT_SENTINEL } from "./constants.ts";

let lastSentCityData = null;
let lastSentLocationAvailable = null;
let cachedPinnedCities = null;

function sendDictionary(dictionary, success, failure) {
  Pebble.sendAppMessage(dictionary, success, function (error) {
    console.log("sendAppMessage failed", JSON.stringify(error));
    if (failure) {
      failure(error);
    }
  });
}

function getPinnedCities() {
  if (cachedPinnedCities) return cachedPinnedCities;

  try {
    const savedSettings = localStorage.getItem('royaleSettings');
    if (savedSettings) {
      const settings = JSON.parse(savedSettings);
      if (settings.SETTING_PINNED_CITIES) {
        cachedPinnedCities = JSON.parse(settings.SETTING_PINNED_CITIES);
        return cachedPinnedCities;
      }
    }
  } catch (e) {
    console.log('Error parsing pinned cities:', e);
  }

  // Default to some fun cities around the world if no setting found
  return [
    "HONOLULU", "ANCHORAGE", "SAN FRANCISCO", "DENVER", "CHICAGO", "NEW YORK",
    "ST. JOHNS", "RIO DE JANEIRO", "LONDON", "BERLIN", "CAIRO", "MOSCOW",
    "DUBAI", "DELHI", "KATHMANDU", "BANGKOK", "BEIJING", "TOKYO", "SYDNEY",
    "WELLINGTON"
  ];
}

function getDateFormat() {
  try {
    const savedSettings = localStorage.getItem('royaleSettings');
    if (savedSettings) {
      const settings = JSON.parse(savedSettings);
      if (settings.SETTING_DATE_FORMAT !== undefined) {
        return parseInt(settings.SETTING_DATE_FORMAT, 10) || 0;
      }
    }
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  } catch (e) { /* empty */ }
  return 0;
}

function getCustomCities() {
  try {
    const savedSettings = localStorage.getItem('royaleSettings');
    if (savedSettings) {
      const settings = JSON.parse(savedSettings);
      if (settings.SETTING_CUSTOM_CITIES) {
        return JSON.parse(settings.SETTING_CUSTOM_CITIES);
      }
    }
  } catch (e) {
    console.log('Error parsing custom cities:', e);
  }
  return [];
}

// Encode a signed 16-bit value as two big-endian bytes, appending to blob array
function pushInt16BE(blob, value) {
  const v = value & 0xFFFF;
  blob.push((v >> 8) & 0xFF);
  blob.push(v & 0xFF);
}

// New blob format: 24 bytes per city
//   bytes 0-15:  city name, null-terminated (up to 15 chars)
//   bytes 16-17: latitude  × 100 as int16, big-endian
//   bytes 18-19: longitude × 100 as int16, big-endian
//   bytes 20-21: offset_minutes as int16, big-endian
//   byte  22:    day_label (0=today, 1=tomorrow, 255=yesterday)
//   byte  23:    is_night (0 or 1)
// ~50km threshold: 0.45 degrees squared ≈ 0.2025
const PROXIMITY_THRESHOLD_SQ = 0.2025;

function findNearestEntryByCoords(entries, lat: number, lon: number) {
  let bestIdx = -1;
  let bestDist = PROXIMITY_THRESHOLD_SQ;

  for (let i = 0; i < entries.length; i++) {
    const entry = entries[i];
    const entryLat = entry.type === 'standard' ? entry.city.lat : entry.cc.lat;
    const entryLon = entry.type === 'standard' ? entry.city.lon : entry.cc.lon;
    const dlat = entryLat - lat;
    const dlon = entryLon - lon;
    const dist = dlat * dlat + dlon * dlon;
    if (dist < bestDist) {
      bestDist = dist;
      bestIdx = i;
    }
  }
  return bestIdx;
}

function computeCityDataBlob(now, coords) {
  const pinnedNames = getPinnedCities();
  const customCities = getCustomCities();

  // Build a flat list of entries (standard + custom), then sort west→east by lon
  let entries = [];

  for (let i = 0; i < CITIES.length; i++) {
    const city = CITIES[i];
    if (!pinnedNames.includes(city.name)) continue;
    entries.push({ type: 'standard', city: city, lon: city.lon });
  }

  for (let j = 0; j < customCities.length; j++) {
    const cc = customCities[j];
    let refCity = null;
    for (let k = 0; k < CITIES.length; k++) {
      if (CITIES[k].name === cc.tzCityName) { refCity = CITIES[k]; break; }
    }
    if (!refCity) continue;
    entries.push({ type: 'custom', cc: cc, refCity: refCity, lon: cc.lon });
  }

  entries.sort(function (a, b) { return a.lon - b.lon; });

  // After sorting, determine proximity match
  let matchedCityIndex = -1;
  if (coords) {
    matchedCityIndex = findNearestEntryByCoords(entries, coords.latitude, coords.longitude);
  }

  const blob = [];
  for (let e = 0; e < entries.length; e++) {
    const entry = entries[e];

    if (entry.type === 'standard') {
      const sc = entry.city;
      const name = sc.name.substring(0, 15);
      for (let n = 0; n < 16; n++) blob.push(n < name.length ? name.charCodeAt(n) : 0);
      pushInt16BE(blob, Math.round(sc.lat * 100));
      pushInt16BE(blob, Math.round(sc.lon * 100));
      pushInt16BE(blob, cityOffsetMinutes(sc, now));
      const label = dayLabelForCity(sc, now);
      blob.push(label < 0 ? FULL_NIGHT_SENTINEL : label);
      blob.push(0); // is_night
    } else {
      const cu = entry.cc;
      const rf = entry.refCity;
      const ccName = cu.displayName.toUpperCase().substring(0, 15);
      for (let cn = 0; cn < 16; cn++) blob.push(cn < ccName.length ? ccName.charCodeAt(cn) : 0);
      pushInt16BE(blob, Math.round(cu.lat * 100));
      pushInt16BE(blob, Math.round(cu.lon * 100));
      pushInt16BE(blob, cityOffsetMinutes(rf, now));
      const ccLabel = dayLabelForCity(rf, now);
      blob.push(ccLabel < 0 ? FULL_NIGHT_SENTINEL : ccLabel);
      blob.push(0); // is_night
    }
  }

  return { blob: blob, matchedCityIndex: matchedCityIndex };
}

function cityDataBlobsEqual(a, b) {
  if (!a || !b || a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) {
    if (a[i] !== b[i]) return false;
  }
  return true;
}

export function sendCityData(coords, locationAvailable) {
  const now = new Date();
  const result = computeCityDataBlob(now, coords);
  const blob = result.blob;
  const matchedCityIndex = result.matchedCityIndex;

  const locationAvailableChanged = (locationAvailable !== null && locationAvailable !== undefined
                                  && locationAvailable !== lastSentLocationAvailable);
  if (cityDataBlobsEqual(blob, lastSentCityData) && !coords && !locationAvailableChanged) {
    return;
  }
  lastSentCityData = blob;
  if (locationAvailable !== null && locationAvailable !== undefined) {
    lastSentLocationAvailable = locationAvailable;
  }

  const CHUNK_SIZE = 120; // 5 cities × 24 bytes
  let chunks = [];
  for (let start = 0; start < blob.length; start += CHUNK_SIZE) {
    const chunk = blob.slice(start, start + CHUNK_SIZE);
    const dict = {
      CITY_DATA_START: start,
      CITY_DATA_COUNT: chunk.length,
      CITY_DATA_TOTAL: blob.length,
      CITY_DATA: chunk
    };

    if (start === 0) {
      dict.SETTING_DATE_FORMAT = getDateFormat();
      dict.USER_UTC_OFFSET_MINUTES = -now.getTimezoneOffset();
      if (coords) {
        dict.USER_LAT = Math.round(coords.latitude * 100);
        dict.USER_LON = Math.round(coords.longitude * 100);
        dict.USER_MATCHED_CITY_INDEX = matchedCityIndex;
      }
      if (locationAvailable === false) {
        dict.LOCATION_AVAILABLE = 0;
      }
    }

    chunks.push(dict);
  }

  function sendChunk(index) {
    if (index >= chunks.length) return;
    sendDictionary(chunks[index], function () {
      sendChunk(index + 1);
    });
  }
  sendChunk(0);
}

export function forceResend() {
  lastSentCityData = null;
}

export function clearCachedPinnedCities() {
  cachedPinnedCities = null;
}
