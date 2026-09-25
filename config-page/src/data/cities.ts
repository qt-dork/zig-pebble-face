export interface City {
  name: string;
  displayName: string;
  timezone: string;
  offset: number; // Standard offset in minutes
}

export interface CustomCity {
  displayName: string; // What appears on the watch (max 15 chars)
  lat: number;
  lon: number;
  tzCityName: string; // References CITIES[].name for DST/offset rules
}

export const CITIES: City[] = [
  { name: "PAGO PAGO", displayName: "Pago Pago", timezone: "America/Pacific", offset: -660 },
  { name: "HONOLULU", displayName: "Honolulu", timezone: "America/Pacific", offset: -600 },
  { name: "ANCHORAGE", displayName: "Anchorage", timezone: "America/Anchorage", offset: -540 },
  { name: "VANCOUVER", displayName: "Vancouver", timezone: "America/Vancouver", offset: -480 },
  { name: "SAN FRANCISCO", displayName: "San Francisco", timezone: "America/Los_Angeles", offset: -480 },
  { name: "EDMONTON", displayName: "Edmonton", timezone: "America/Edmonton", offset: -420 },
  { name: "DENVER", displayName: "Denver", timezone: "America/Denver", offset: -420 },
  { name: "MEXICO CITY", displayName: "Mexico City", timezone: "America/Mexico_City", offset: -360 },
  { name: "CHICAGO", displayName: "Chicago", timezone: "America/Chicago", offset: -360 },
  { name: "NEW YORK", displayName: "New York", timezone: "America/New_York", offset: -300 },
  { name: "SANTIAGO", displayName: "Santiago", timezone: "America/Santiago", offset: -240 },
  { name: "HALIFAX", displayName: "Halifax", timezone: "America/Halifax", offset: -240 },
  { name: "ST. JOHNS", displayName: "St. John's", timezone: "America/St_Johns", offset: -210 },
  { name: "RIO DE JANEIRO", displayName: "Rio de Janeiro", timezone: "America/Sao_Paulo", offset: -180 },
  { name: "F. DE NORONHA", displayName: "F. de Noronha", timezone: "America/Noronha", offset: -120 },
  { name: "PRAIA", displayName: "Praia", timezone: "Atlantic/Cape_Verde", offset: -60 },
  { name: "UTC", displayName: "UTC", timezone: "UTC", offset: 0 },
  { name: "LISBON", displayName: "Lisbon", timezone: "Europe/Lisbon", offset: 0 },
  { name: "LONDON", displayName: "London", timezone: "Europe/London", offset: 0 },
  { name: "MADRID", displayName: "Madrid", timezone: "Europe/Madrid", offset: 60 },
  { name: "PARIS", displayName: "Paris", timezone: "Europe/Paris", offset: 60 },
  { name: "ROME", displayName: "Rome", timezone: "Europe/Rome", offset: 60 },
  { name: "BERLIN", displayName: "Berlin", timezone: "Europe/Berlin", offset: 60 },
  { name: "STOCKHOLM", displayName: "Stockholm", timezone: "Europe/Stockholm", offset: 60 },
  { name: "ATHENS", displayName: "Athens", timezone: "Europe/Athens", offset: 120 },
  { name: "CAIRO", displayName: "Cairo", timezone: "Africa/Cairo", offset: 120 },
  { name: "JERUSALEM", displayName: "Jerusalem", timezone: "Asia/Jerusalem", offset: 120 },
  { name: "MOSCOW", displayName: "Moscow", timezone: "Europe/Moscow", offset: 180 },
  { name: "JEDDAH", displayName: "Jeddah", timezone: "Asia/Riyadh", offset: 180 },
  { name: "TEHRAN", displayName: "Tehran", timezone: "Asia/Tehran", offset: 210 },
  { name: "DUBAI", displayName: "Dubai", timezone: "Asia/Dubai", offset: 240 },
  { name: "KABUL", displayName: "Kabul", timezone: "Asia/Kabul", offset: 270 },
  { name: "KARACHI", displayName: "Karachi", timezone: "Asia/Karachi", offset: 300 },
  { name: "DELHI", displayName: "Delhi", timezone: "Asia/Kolkata", offset: 330 },
  { name: "KATHMANDU", displayName: "Kathmandu", timezone: "Asia/Kathmandu", offset: 345 },
  { name: "DHAKA", displayName: "Dhaka", timezone: "Asia/Dhaka", offset: 360 },
  { name: "YANGON", displayName: "Yangon", timezone: "Asia/Yangon", offset: 390 },
  { name: "BANGKOK", displayName: "Bangkok", timezone: "Asia/Bangkok", offset: 420 },
  { name: "SINGAPORE", displayName: "Singapore", timezone: "Asia/Singapore", offset: 480 },
  { name: "HONG KONG", displayName: "Hong Kong", timezone: "Asia/Hong_Kong", offset: 480 },
  { name: "BEIJING", displayName: "Beijing", timezone: "Asia/Shanghai", offset: 480 },
  { name: "TAIPEI", displayName: "Taipei", timezone: "Asia/Taipei", offset: 480 },
  { name: "SEOUL", displayName: "Seoul", timezone: "Asia/Seoul", offset: 540 },
  { name: "TOKYO", displayName: "Tokyo", timezone: "Asia/Tokyo", offset: 540 },
  { name: "ADELAIDE", displayName: "Adelaide", timezone: "Australia/Adelaide", offset: 570 },
  { name: "GUAM", displayName: "Guam", timezone: "Pacific/Guam", offset: 600 },
  { name: "SYDNEY", displayName: "Sydney", timezone: "Australia/Sydney", offset: 600 },
  { name: "NOUMEA", displayName: "Noumea", timezone: "Pacific/Noumea", offset: 660 },
  { name: "WELLINGTON", displayName: "Wellington", timezone: "Pacific/Auckland", offset: 720 }
];
