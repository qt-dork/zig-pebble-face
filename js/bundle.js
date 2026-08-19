"use strict";
(() => {
  // src/settings.html
  var settings_default = `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <title>Heartburn Settings</title>
  </head>
  <body style="margin: 0 auto; padding: 0 1rem; max-width: 600px; background: #333; color: #fff; font-family: sans-serif">
    <form>
      <h3 style="margin-bottom: 1rem; text-align: center; text-transform: uppercase; letter-spacing: 0.025em">Heartburn Settings</h3>

      <div style="padding: 0.75rem; background: #484848; border-radius: 0.25rem">
        <label style="display: flex; justify-content: space-between; align-items: center">
          <span>Temperature Unit</span>
          <select id="temperature-unit-select" style="background: #5b5b5b; color: #fff; border: 0; border-radius: 0.25rem; padding: 0.3rem 0.5rem">
            <option value="C">Celsius (&deg;C)</option>
            <option value="F">Fahrenheit (&deg;F)</option>
          </select>
        </label>
      </div>

      <div style="text-align: center; margin-top: 1rem">
        <button
          id="submit-btn"
          type="submit"
          style="
            background: #ff4700;
            color: #fff;
            border: 0;
            border-radius: 0.25rem;
            text-transform: uppercase;
            font-weight: bold;
            min-width: 12rem;
            padding: 0.6rem;
            cursor: pointer;
          "
        >
          Save
        </button>
      </div>
    </form>

    <script>
      document.getElementById('submit-btn').addEventListener('click', function (e) {
        e.preventDefault();
        var settings = { temperatureUnit: document.getElementById('temperature-unit-select').value };
        window.location.href = 'pebblejs://close#' + encodeURIComponent(JSON.stringify(settings));
      });

      var settings = JSON.parse('$$SETTINGS$$');
      document.getElementById('temperature-unit-select').value = settings.temperatureUnit === 'F' ? 'F' : 'C';
    <\/script>
  </body>
</html>
`;

  // src/index.ts
  var CACHE_EXPIRATION_MS = 15 * 60 * 1e3;
  async function geolocate() {
    return new Promise((resolve, reject) => {
      navigator.geolocation.getCurrentPosition(resolve, reject, { timeout: 15e3, maximumAge: 6e4 });
    });
  }
  async function fetch(method, url) {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      xhr.onload = function() {
        if (xhr.status === 200) {
          resolve(xhr.response);
        } else {
          reject(xhr.statusText);
        }
      };
      xhr.onerror = function() {
        reject(xhr.statusText);
      };
      xhr.open(method, url);
      xhr.send();
    });
  }
  async function pebbleSendAppMessage(dictionary) {
    return new Promise((resolve, reject) => {
      Pebble.sendAppMessage(dictionary, resolve, reject);
    });
  }
  function mapWeatherCode(code) {
    switch (code) {
      case 0:
      // Clear Sky
      case 1:
        return "Clear";
      case 2:
        return "PartlyCloudy";
      case 3:
        return "Clouds";
      case 45:
      // Fog
      case 48:
        return "Foggy";
      case 51:
      // Drizzle: Light
      case 53:
      // Drizzle: Moderate
      case 55:
      // Drizzle: Dense
      case 56:
        return "Drizzle";
      case 57:
        return "Hail";
      case 61:
        return "Drizzle";
      case 63:
      // Rain: Moderate
      case 65:
        return "Rain";
      case 66:
        return "Drizzle";
      case 67:
        return "Hail";
      case 71:
        return "Snow";
      case 73:
      // Snow Fall: Moderate
      case 75:
        return "HeavySnow";
      case 77:
        return "Snow";
      case 80:
        return "Drizzle";
      case 81:
      // Rain Showers: Moderate
      case 82:
        return "Rain";
      case 85:
        return "Snow";
      case 86:
        return "HeavySnow";
      case 95:
        return "Lightning";
      case 96:
        return "CloudyLightning";
      default:
        return "Unknown";
    }
  }
  async function refreshWeather() {
    try {
      if (localStorage.getItem("weatherCache")) {
        const weatherCache = JSON.parse(localStorage.getItem("weatherCache"));
        const [currentTime, cacheTime] = [/* @__PURE__ */ new Date(), new Date(weatherCache["timestamp"])];
        if (currentTime > cacheTime && currentTime.valueOf() - cacheTime.valueOf() < CACHE_EXPIRATION_MS) {
          console.log("Using cached weather from " + cacheTime);
          await pebbleSendAppMessage(weatherCache.weatherAppMessage);
          return;
        }
      }
    } catch (err) {
      console.log("Error looking up weather cache:", err);
      return;
    }
    try {
      const location = await geolocate();
      console.log("Looking up weather at " + /* @__PURE__ */ new Date());
      const weather = JSON.parse(
        await fetch(
          "GET",
          "https://api.open-meteo.com/v1/forecast?latitude=" + location.coords.latitude + "&longitude=" + location.coords.longitude + "&daily=sunrise,sunset&current=temperature_2m,weather_code&past_days=1&forecast_days=2&temperature_unit=" + (localStorage.getItem("temperatureUnit") === "F" ? "fahrenheit" : "celsius")
        )
      );
      const currentTime = /* @__PURE__ */ new Date();
      const weatherAppMessage = {
        WEATHER_CONDITIONS: mapWeatherCode(weather.current.weather_code),
        WEATHER_TEMPERATURE: Math.round(weather.current.temperature_2m),
        WEATHER_SUNRISE: weather.daily.sunrise[weather.daily.sunrise.map((d) => currentTime < /* @__PURE__ */ new Date(d + "Z")).indexOf(true)],
        WEATHER_SUNSET: weather.daily.sunset[weather.daily.sunset.map((d) => currentTime < /* @__PURE__ */ new Date(d + "Z")).indexOf(true)]
      };
      localStorage.setItem("weatherCache", JSON.stringify({ timestamp: currentTime, weatherAppMessage }));
      await pebbleSendAppMessage(weatherAppMessage);
    } catch (err) {
      await pebbleSendAppMessage({ WEATHER_ERROR: 1 });
      throw err;
    }
  }
  Pebble.addEventListener("appmessage", async function(e) {
    if (e.payload["REQUEST_WEATHER"]) {
      try {
        await refreshWeather();
      } catch (err) {
        console.log("Error fetching weather:", err);
      }
    }
  });
  Pebble.addEventListener("showConfiguration", function() {
    Pebble.openURL(
      "data:text/html;charset=utf-8," + encodeURIComponent(settings_default.replace("$$SETTINGS$$", JSON.stringify({ temperatureUnit: localStorage.getItem("temperatureUnit") ?? "C" })))
    );
  });
  Pebble.addEventListener("webviewclosed", async function(e) {
    if (!e.response) return;
    try {
      const config = JSON.parse(decodeURIComponent(e.response));
      localStorage.setItem("temperatureUnit", config["temperatureUnit"]);
    } catch (err) {
      console.log("Error processing configuration:", err);
      return;
    }
    localStorage.removeItem("weatherCache");
  });
})();
