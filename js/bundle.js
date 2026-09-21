"use strict";
(() => {
  // src/cities.ts
  var CITIES = [
    { name: "PAGO PAGO", lat: -14.27, lon: -170.7, std: -660, dst: null },
    { name: "HONOLULU", lat: 21.31, lon: -157.86, std: -600, dst: null },
    { name: "ANCHORAGE", lat: 61.22, lon: -149.9, std: -540, dst: { off: 60, sm: 3, sw: 2, sd: 0, em: 11, ew: 1, ed: 0 } },
    { name: "VANCOUVER", lat: 49.28, lon: -123.12, std: -480, dst: { off: 60, sm: 3, sw: 2, sd: 0, em: 11, ew: 1, ed: 0 } },
    { name: "SAN FRANCISCO", lat: 37.77, lon: -122.42, std: -480, dst: { off: 60, sm: 3, sw: 2, sd: 0, em: 11, ew: 1, ed: 0 } },
    { name: "EDMONTON", lat: 53.54, lon: -113.49, std: -420, dst: { off: 60, sm: 3, sw: 2, sd: 0, em: 11, ew: 1, ed: 0 } },
    { name: "DENVER", lat: 39.74, lon: -104.99, std: -420, dst: { off: 60, sm: 3, sw: 2, sd: 0, em: 11, ew: 1, ed: 0 } },
    { name: "MEXICO CITY", lat: 19.43, lon: -99.13, std: -360, dst: null },
    { name: "CHICAGO", lat: 41.88, lon: -87.63, std: -360, dst: { off: 60, sm: 3, sw: 2, sd: 0, em: 11, ew: 1, ed: 0 } },
    { name: "NEW YORK", lat: 40.71, lon: -74.01, std: -300, dst: { off: 60, sm: 3, sw: 2, sd: 0, em: 11, ew: 1, ed: 0 } },
    { name: "SANTIAGO", lat: -33.45, lon: -70.67, std: -240, dst: { off: 60, sm: 9, sw: 1, sd: 6, em: 4, ew: 1, ed: 6 } },
    { name: "HALIFAX", lat: 44.65, lon: -63.57, std: -240, dst: { off: 60, sm: 3, sw: 2, sd: 0, em: 11, ew: 1, ed: 0 } },
    { name: "ST. JOHNS", lat: 47.56, lon: -52.71, std: -210, dst: { off: 60, sm: 3, sw: 2, sd: 0, em: 11, ew: 1, ed: 0 } },
    { name: "RIO DE JANEIRO", lat: -22.91, lon: -43.17, std: -180, dst: null },
    { name: "F. DE NORONHA", lat: -3.86, lon: -32.42, std: -120, dst: null },
    { name: "PRAIA", lat: 14.92, lon: -23.51, std: -60, dst: null },
    { name: "UTC", lat: 0, lon: 0, std: 0, dst: null },
    { name: "LISBON", lat: 38.72, lon: -9.14, std: 0, dst: { off: 60, sm: 3, sw: 0, sd: 0, em: 10, ew: 0, ed: 0 } },
    { name: "LONDON", lat: 51.51, lon: -0.13, std: 0, dst: { off: 60, sm: 3, sw: 0, sd: 0, em: 10, ew: 0, ed: 0 } },
    { name: "MADRID", lat: 40.42, lon: -3.7, std: 60, dst: { off: 60, sm: 3, sw: 0, sd: 0, em: 10, ew: 0, ed: 0 } },
    { name: "PARIS", lat: 48.86, lon: 2.35, std: 60, dst: { off: 60, sm: 3, sw: 0, sd: 0, em: 10, ew: 0, ed: 0 } },
    { name: "ROME", lat: 41.9, lon: 12.5, std: 60, dst: { off: 60, sm: 3, sw: 0, sd: 0, em: 10, ew: 0, ed: 0 } },
    { name: "BERLIN", lat: 52.52, lon: 13.41, std: 60, dst: { off: 60, sm: 3, sw: 0, sd: 0, em: 10, ew: 0, ed: 0 } },
    { name: "STOCKHOLM", lat: 59.33, lon: 18.07, std: 60, dst: { off: 60, sm: 3, sw: 0, sd: 0, em: 10, ew: 0, ed: 0 } },
    { name: "ATHENS", lat: 37.98, lon: 23.73, std: 120, dst: { off: 60, sm: 3, sw: 0, sd: 0, em: 10, ew: 0, ed: 0 } },
    { name: "CAIRO", lat: 30.04, lon: 31.24, std: 120, dst: null },
    { name: "JERUSALEM", lat: 31.77, lon: 35.23, std: 120, dst: { off: 60, sm: 3, sw: 0, sd: 5, em: 10, ew: 1, ed: 0 } },
    { name: "MOSCOW", lat: 55.76, lon: 37.62, std: 180, dst: null },
    { name: "JEDDAH", lat: 21.49, lon: 39.19, std: 180, dst: null },
    { name: "TEHRAN", lat: 35.69, lon: 51.39, std: 210, dst: { off: 60, sm: 3, sd: 21, em: 9, ed: 21 } },
    { name: "DUBAI", lat: 25.2, lon: 55.27, std: 240, dst: null },
    { name: "KABUL", lat: 34.53, lon: 69.17, std: 270, dst: null },
    { name: "KARACHI", lat: 24.86, lon: 67.01, std: 300, dst: null },
    { name: "DELHI", lat: 28.61, lon: 77.21, std: 330, dst: null },
    { name: "KATHMANDU", lat: 27.72, lon: 85.32, std: 345, dst: null },
    { name: "DHAKA", lat: 23.81, lon: 90.41, std: 360, dst: null },
    { name: "YANGON", lat: 16.87, lon: 96.2, std: 390, dst: null },
    { name: "BANGKOK", lat: 13.76, lon: 100.5, std: 420, dst: null },
    { name: "SINGAPORE", lat: 1.35, lon: 103.82, std: 480, dst: null },
    { name: "HONG KONG", lat: 22.32, lon: 114.17, std: 480, dst: null },
    { name: "BEIJING", lat: 39.9, lon: 116.4, std: 480, dst: null },
    { name: "TAIPEI", lat: 25.03, lon: 121.57, std: 480, dst: null },
    { name: "SEOUL", lat: 37.57, lon: 126.98, std: 540, dst: null },
    { name: "TOKYO", lat: 35.68, lon: 139.69, std: 540, dst: null },
    { name: "ADELAIDE", lat: -34.93, lon: 138.6, std: 570, dst: { off: 60, sm: 10, sw: 1, sd: 0, em: 4, ew: 1, ed: 0 } },
    { name: "GUAM", lat: 13.44, lon: 144.79, std: 600, dst: null },
    { name: "SYDNEY", lat: -33.87, lon: 151.21, std: 600, dst: { off: 60, sm: 10, sw: 1, sd: 0, em: 4, ew: 1, ed: 0 } },
    { name: "NOUMEA", lat: -22.28, lon: 166.46, std: 660, dst: null },
    { name: "WELLINGTON", lat: -41.29, lon: 174.78, std: 720, dst: { off: 60, sm: 9, sw: 0, sd: 0, em: 4, ew: 1, ed: 0 } }
  ];
  function nthWeekdayOfMonth(year, month, n, dayOfWeek) {
    if (n === 0) {
      var nextMonth = new Date(Date.UTC(year, month, 1));
      nextMonth.setUTCDate(0);
      var lastDay = nextMonth.getUTCDate();
      var lastDow = nextMonth.getUTCDay();
      var diff = lastDow - dayOfWeek;
      if (diff < 0) diff += 7;
      return lastDay - diff;
    }
    var first = new Date(Date.UTC(year, month - 1, 1));
    var firstDow = first.getUTCDay();
    var diff = dayOfWeek - firstDow;
    if (diff < 0) diff += 7;
    return 1 + diff + (n - 1) * 7;
  }
  function isDstActive(city, now) {
    var rule = city.dst;
    if (!rule) return false;
    var year = now.getUTCFullYear();
    var startDay, endDay;
    if (rule.sd !== void 0 && rule.sw === void 0) {
      startDay = new Date(Date.UTC(year, rule.sm - 1, rule.sd));
      endDay = new Date(Date.UTC(year, rule.em - 1, rule.ed));
    } else {
      startDay = new Date(Date.UTC(year, rule.sm - 1, nthWeekdayOfMonth(year, rule.sm, rule.sw, rule.sd)));
      endDay = new Date(Date.UTC(year, rule.em - 1, nthWeekdayOfMonth(year, rule.em, rule.ew, rule.ed)));
    }
    return now >= startDay && now < endDay;
  }
  function cityOffsetMinutes(city, now) {
    if (isDstActive(city, now)) {
      return city.std + city.dst.off;
    }
    return city.std;
  }
  function dayLabelForCity(city, now) {
    var offsetDiff = cityOffsetMinutes(city, now) + now.getTimezoneOffset();
    var cityTotalMinutes = now.getHours() * 60 + now.getMinutes() + offsetDiff;
    var dayDiff = Math.floor(cityTotalMinutes / 1440);
    if (dayDiff <= -1) return -1;
    if (dayDiff >= 1) return 1;
    return 0;
  }

  // src/constants.ts
  var FULL_NIGHT_SENTINEL = 255;

  // src/city-data.ts
  var lastSentCityData = null;
  var lastSentLocationAvailable = null;
  var cachedPinnedCities = null;
  function sendDictionary(dictionary, success, failure) {
    Pebble.sendAppMessage(dictionary, success, function(error) {
      console.log("sendAppMessage failed", JSON.stringify(error));
      if (failure) {
        failure(error);
      }
    });
  }
  function getPinnedCities() {
    if (cachedPinnedCities) return cachedPinnedCities;
    try {
      var savedSettings = localStorage.getItem("royaleSettings");
      if (savedSettings) {
        var settings = JSON.parse(savedSettings);
        if (settings.SETTING_PINNED_CITIES) {
          cachedPinnedCities = JSON.parse(settings.SETTING_PINNED_CITIES);
          return cachedPinnedCities;
        }
      }
    } catch (e) {
      console.log("Error parsing pinned cities:", e);
    }
    return [
      "HONOLULU",
      "ANCHORAGE",
      "SAN FRANCISCO",
      "DENVER",
      "CHICAGO",
      "NEW YORK",
      "ST. JOHNS",
      "RIO DE JANEIRO",
      "LONDON",
      "BERLIN",
      "CAIRO",
      "MOSCOW",
      "DUBAI",
      "DELHI",
      "KATHMANDU",
      "BANGKOK",
      "BEIJING",
      "TOKYO",
      "SYDNEY",
      "WELLINGTON"
    ];
  }
  function getDateFormat() {
    try {
      var savedSettings = localStorage.getItem("royaleSettings");
      if (savedSettings) {
        var settings = JSON.parse(savedSettings);
        if (settings.SETTING_DATE_FORMAT !== void 0) {
          return parseInt(settings.SETTING_DATE_FORMAT, 10) || 0;
        }
      }
    } catch (e) {
    }
    return 0;
  }
  function getCustomCities() {
    try {
      var savedSettings = localStorage.getItem("royaleSettings");
      if (savedSettings) {
        var settings = JSON.parse(savedSettings);
        if (settings.SETTING_CUSTOM_CITIES) {
          return JSON.parse(settings.SETTING_CUSTOM_CITIES);
        }
      }
    } catch (e) {
      console.log("Error parsing custom cities:", e);
    }
    return [];
  }
  function pushInt16BE(blob, value) {
    var v = value & 65535;
    blob.push(v >> 8 & 255);
    blob.push(v & 255);
  }
  var PROXIMITY_THRESHOLD_SQ = 0.2025;
  function findNearestEntryByCoords(entries, lat, lon) {
    var bestIdx = -1;
    var bestDist = PROXIMITY_THRESHOLD_SQ;
    for (var i = 0; i < entries.length; i++) {
      var entry = entries[i];
      var entryLat = entry.type === "standard" ? entry.city.lat : entry.cc.lat;
      var entryLon = entry.type === "standard" ? entry.city.lon : entry.cc.lon;
      var dlat = entryLat - lat;
      var dlon = entryLon - lon;
      var dist = dlat * dlat + dlon * dlon;
      if (dist < bestDist) {
        bestDist = dist;
        bestIdx = i;
      }
    }
    return bestIdx;
  }
  function computeCityDataBlob(now, coords) {
    var pinnedNames = getPinnedCities();
    var customCities = getCustomCities();
    var entries = [];
    for (var i = 0; i < CITIES.length; i++) {
      var city = CITIES[i];
      if (!pinnedNames.includes(city.name)) continue;
      entries.push({ type: "standard", city, lon: city.lon });
    }
    for (var j = 0; j < customCities.length; j++) {
      var cc = customCities[j];
      var refCity = null;
      for (var k = 0; k < CITIES.length; k++) {
        if (CITIES[k].name === cc.tzCityName) {
          refCity = CITIES[k];
          break;
        }
      }
      if (!refCity) continue;
      entries.push({ type: "custom", cc, refCity, lon: cc.lon });
    }
    entries.sort(function(a, b) {
      return a.lon - b.lon;
    });
    var matchedCityIndex = -1;
    if (coords) {
      matchedCityIndex = findNearestEntryByCoords(entries, coords.latitude, coords.longitude);
    }
    var blob = [];
    for (var e = 0; e < entries.length; e++) {
      var entry = entries[e];
      if (entry.type === "standard") {
        var sc = entry.city;
        var name = sc.name.substring(0, 15);
        for (var n = 0; n < 16; n++) blob.push(n < name.length ? name.charCodeAt(n) : 0);
        pushInt16BE(blob, Math.round(sc.lat * 100));
        pushInt16BE(blob, Math.round(sc.lon * 100));
        pushInt16BE(blob, cityOffsetMinutes(sc, now));
        var label = dayLabelForCity(sc, now);
        blob.push(label < 0 ? FULL_NIGHT_SENTINEL : label);
        blob.push(0);
      } else {
        var cu = entry.cc;
        var rf = entry.refCity;
        var ccName = cu.displayName.toUpperCase().substring(0, 15);
        for (var cn = 0; cn < 16; cn++) blob.push(cn < ccName.length ? ccName.charCodeAt(cn) : 0);
        pushInt16BE(blob, Math.round(cu.lat * 100));
        pushInt16BE(blob, Math.round(cu.lon * 100));
        pushInt16BE(blob, cityOffsetMinutes(rf, now));
        var ccLabel = dayLabelForCity(rf, now);
        blob.push(ccLabel < 0 ? FULL_NIGHT_SENTINEL : ccLabel);
        blob.push(0);
      }
    }
    return { blob, matchedCityIndex };
  }
  function cityDataBlobsEqual(a, b) {
    if (!a || !b || a.length !== b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] !== b[i]) return false;
    }
    return true;
  }
  function sendCityData(coords, locationAvailable2) {
    const now = /* @__PURE__ */ new Date();
    const result = computeCityDataBlob(now, coords);
    const blob = result.blob;
    const matchedCityIndex = result.matchedCityIndex;
    const locationAvailableChanged = locationAvailable2 !== null && locationAvailable2 !== void 0 && locationAvailable2 !== lastSentLocationAvailable;
    if (cityDataBlobsEqual(blob, lastSentCityData) && !coords && !locationAvailableChanged) {
      return;
    }
    lastSentCityData = blob;
    if (locationAvailable2 !== null && locationAvailable2 !== void 0) {
      lastSentLocationAvailable = locationAvailable2;
    }
    var CHUNK_SIZE = 120;
    var chunks = [];
    for (var start = 0; start < blob.length; start += CHUNK_SIZE) {
      var chunk = blob.slice(start, start + CHUNK_SIZE);
      var dict = {
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
        if (locationAvailable2 === false) {
          dict.LOCATION_AVAILABLE = 0;
        }
      }
      chunks.push(dict);
    }
    function sendChunk(index) {
      if (index >= chunks.length) return;
      sendDictionary(chunks[index], function() {
        sendChunk(index + 1);
      });
    }
    sendChunk(0);
  }
  function forceResend() {
    lastSentCityData = null;
  }
  function clearCachedPinnedCities() {
    cachedPinnedCities = null;
  }

  // src/index.ts
  var configDataUri = "http://localhost:3000/royale/";
  var dstCheckTimer = null;
  var locationAvailable = null;
  function startDstChecks() {
    if (dstCheckTimer) clearInterval(dstCheckTimer);
    dstCheckTimer = setInterval(function() {
      sendCityData(null, locationAvailable);
    }, 30 * 60 * 1e3);
  }
  Pebble.addEventListener("ready", function() {
    startDstChecks();
    sendCityData(null, locationAvailable);
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(function(pos) {
        locationAvailable = true;
        sendCityData(pos.coords, locationAvailable);
      }, function() {
        locationAvailable = false;
        sendCityData(null, locationAvailable);
      }, {
        enableHighAccuracy: false,
        timeout: 5e3,
        maximumAge: 6e5
      });
    } else {
      locationAvailable = false;
      sendCityData(null, locationAvailable);
    }
  });
  Pebble.addEventListener("appmessage", function(event) {
    const payload = event.payload || {};
    if (payload.REQUEST_CITY_DATA) {
      forceResend();
      sendCityData(null, locationAvailable);
      return;
    }
  });
  Pebble.addEventListener("showConfiguration", function() {
    var url = configDataUri;
    var watchInfo = Pebble.getActiveWatchInfo();
    url += (url.indexOf("?") === -1 ? "?" : "&") + "watchInfo=" + encodeURIComponent(JSON.stringify({
      platform: watchInfo.platform,
      model: watchInfo.model,
      language: watchInfo.language,
      firmware: {
        major: watchInfo.firmware.major,
        minor: watchInfo.firmware.minor
      }
    }));
    var persistedSettings = localStorage.getItem("royaleSettings");
    if (persistedSettings) {
      try {
        var settings = JSON.parse(persistedSettings);
        url += "&settings=" + encodeURIComponent(JSON.stringify(settings));
      } catch (e) {
        console.log("Error loading persisted settings:", e);
      }
    }
    Pebble.openURL(url);
  });
  Pebble.addEventListener("webviewclosed", function(e) {
    if (!e.response || e.response === "CANCELLED" || e.response === "null" || e.response === "{}") {
      return;
    }
    var configData;
    try {
      configData = JSON.parse(decodeURIComponent(e.response));
    } catch (err) {
      console.log("Error parsing configuration response: " + err);
      try {
        configData = JSON.parse(e.response);
      } catch (err2) {
        console.log("Failed to parse config data even without decoding");
        return;
      }
    }
    if (configData.return_to) {
      delete configData.return_to;
    }
    localStorage.setItem("royaleSettings", JSON.stringify(configData));
    clearCachedPinnedCities();
    forceResend();
    sendCityData(null, locationAvailable);
  });
})();
