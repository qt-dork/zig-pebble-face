// pebble-watchface-heartburn v1.3
// https://github.com/vsergeev/pebble-watchface-heartburn

import settingsPage from './settings.html';

////////////////////////////////////////////////////////////////////////////////
// Constants
////////////////////////////////////////////////////////////////////////////////

const CACHE_EXPIRATION_MS = 15 * 60 * 1000;

////////////////////////////////////////////////////////////////////////////////
// Helpers
////////////////////////////////////////////////////////////////////////////////

async function geolocate(): Promise<GeolocationPosition> {
  return new Promise((resolve, reject) => {
    navigator.geolocation.getCurrentPosition(resolve, reject, { timeout: 15000, maximumAge: 60000 });
  });
}

async function fetch(method: string, url: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.onload = function () {
      if (xhr.status === 200) {
        resolve(xhr.response);
      } else {
        reject(xhr.statusText);
      }
    };
    xhr.onerror = function () {
      reject(xhr.statusText);
    };
    xhr.open(method, url);
    xhr.send();
  });
}

async function pebbleSendAppMessage(dictionary: Record<string, any>): Promise<any> {
  return new Promise((resolve, reject) => {
    Pebble.sendAppMessage(dictionary, resolve, reject);
  });
}

////////////////////////////////////////////////////////////////////////////////
// Weather Fetch
////////////////////////////////////////////////////////////////////////////////

function mapWeatherCode(code: number): string {
  switch (code) {
    case 0: // Clear Sky
    case 1: // Mainly Clear
      return 'Clear';
    case 2: // Partly Cloudy
      return 'PartlyCloudy';
    case 3: // Overcast
      return 'Clouds';
    case 45: // Fog
    case 48: // Depositing Rime Fog
      return 'Foggy';
    case 51: // Drizzle: Light
    case 53: // Drizzle: Moderate
    case 55: // Drizzle: Dense
    case 56: // Freezing Drizzle: Light
      return 'Drizzle';
    case 57: // Freezing Drizzle: Dense
      return 'Hail';
    case 61: // Rain: Slight
      return 'Drizzle';
    case 63: // Rain: Moderate
    case 65: // Rain: Heavy
      return 'Rain';
    case 66: // Freezing Rain: Light
      return 'Drizzle';
    case 67: // Freezing Rain: Heavy
      return 'Hail';
    case 71: // Snow Fall: Slight
      return 'Snow';
    case 73: // Snow Fall: Moderate
    case 75: // Snow Fall: Heavy
      return 'HeavySnow';
    case 77: // Snow Grains
      return 'Snow';
    case 80: // Rain Showers: Slight
      return 'Drizzle';
    case 81: // Rain Showers: Moderate
    case 82: // Rain Showers: Violent
      return 'Rain';
    case 85: // Snow Showers: Slight
      return 'Snow';
    case 86: // Snow Showers: Heavy
      return 'HeavySnow';
    case 95: // Thunderstorm: Slight
      return 'Lightning';
    case 96: // Thunderstorm: Moderate
      return 'CloudyLightning';
    default:
      return 'Unknown';
  }
}

async function refreshWeather(): Promise<void> {
  // Try cache first
  try {
    if (localStorage.getItem('weatherCache')) {
      const weatherCache = JSON.parse(localStorage.getItem('weatherCache') as string);

      const [currentTime, cacheTime] = [new Date(), new Date(weatherCache['timestamp'])];
      if (currentTime > cacheTime && currentTime.valueOf() - cacheTime.valueOf() < CACHE_EXPIRATION_MS) {
        console.log('Using cached weather from ' + cacheTime);
        await pebbleSendAppMessage(weatherCache.weatherAppMessage);
        return;
      }
    }
  } catch (err) {
    console.log('Error looking up weather cache:', err);
    return;
  }

  // Look up weather
  try {
    const location = await geolocate();

    console.log('Looking up weather at ' + new Date());

    const weather = JSON.parse(
      await fetch(
        'GET',
        'https://api.open-meteo.com/v1/forecast?latitude=' +
          location.coords.latitude +
          '&longitude=' +
          location.coords.longitude +
          '&daily=sunrise,sunset&current=temperature_2m,weather_code&past_days=1&forecast_days=2&temperature_unit=' +
          (localStorage.getItem('temperatureUnit') === 'F' ? 'fahrenheit' : 'celsius'),
      ),
    );

    const currentTime = new Date();

    const weatherAppMessage = {
      WEATHER_CONDITIONS: mapWeatherCode(weather.current.weather_code),
      WEATHER_TEMPERATURE: Math.round(weather.current.temperature_2m),
      WEATHER_SUNRISE: weather.daily.sunrise[weather.daily.sunrise.map((d: string) => currentTime < new Date(d + 'Z')).indexOf(true)],
      WEATHER_SUNSET: weather.daily.sunset[weather.daily.sunset.map((d: string) => currentTime < new Date(d + 'Z')).indexOf(true)],
    };

    localStorage.setItem('weatherCache', JSON.stringify({ timestamp: currentTime, weatherAppMessage }));

    await pebbleSendAppMessage(weatherAppMessage);
  } catch (err) {
    await pebbleSendAppMessage({ WEATHER_ERROR: 1 });
    throw err;
  }
}

////////////////////////////////////////////////////////////////////////////////
// Event Listeners
////////////////////////////////////////////////////////////////////////////////

Pebble.addEventListener('appmessage', async function (e: { type: string; payload: any; response: any }) {
  if (e.payload['REQUEST_WEATHER']) {
    try {
      await refreshWeather();
    } catch (err) {
      console.log('Error fetching weather:', err);
    }
  }
});

Pebble.addEventListener('showConfiguration', function () {
  Pebble.openURL(
    'data:text/html;charset=utf-8,' +
      encodeURIComponent(settingsPage.replace('$$SETTINGS$$', JSON.stringify({ temperatureUnit: localStorage.getItem('temperatureUnit') ?? 'C' }))),
  );
});

Pebble.addEventListener('webviewclosed', async function (e) {
  if (!e.response) return;

  try {
    const config = JSON.parse(decodeURIComponent(e.response));
    localStorage.setItem('temperatureUnit', config['temperatureUnit']);
  } catch (err) {
    console.log('Error processing configuration:', err);
    return;
  }

  // Clear weather cache
  localStorage.removeItem('weatherCache');
});
