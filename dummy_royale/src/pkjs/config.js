module.exports = [
	{
		"type": "heading",
		"defaultValue": "Royale",
	},
	{
		"type": "text",
		"defaultValue":
			"<p>By Evie Finch. Inspired by the Casio AE1200. Written in Zig.</p>",
	},
	{
		"type": "section",
		"items": [
			{
				"type": "heading",
				"defaultValue": "Preferences",
			},
			{
				"type": "select",
				"label": "Screen Update Frequency",
				"messageKey": "SettingsEnableSeconds",
				"defaultValue": "0",
				"options": [
					{
						"label": "Per Second",
						"value": "0",
					},
					{
						"label": "Per 15 Seconds",
						"value": "1",
					},
					{
						"label": "Per Minute",
						"value": "2",
					},
				],
			},
			{
				"type": "select",
				"label": "Tracked Time Zone",
				"messageKey": "SettingsTimeZone",
				"defaultValue": "-1",
				"options": [
					{
						"label": "None (Default)",
						"value": "-1",
					},
					{
						"label": "Pago Pago (UTC-11)",
						"value": "0",
					},
					{
						"label": "Honolulu (UTC-10)",
						"value": "1",
					},
					{
						"label": "Anchorage (UTC-9)",
						"value": "2",
					},
					{
						"label": "Vancouver (UTC-8)",
						"value": "3",
					},
					{
						"label": "San Francisco (UTC-8)",
						"value": "4",
					},
					{
						"label": "Edmonton (UTC-7)",
						"value": "5",
					},
					{
						"label": "Denver (UTC-7)",
						"value": "6",
					},
					{
						"label": "Mexico City (UTC-6)",
						"value": "7",
					},
					{
						"label": "Chicago (UTC-6)",
						"value": "8",
					},
					{
						"label": "New York (UTC-5)",
						"value": "9",
					},
					{
						"label": "Santiago (UTC-4)",
						"value": "10",
					},
					{
						"label": "Halifax (UTC-4)",
						"value": "11",
					},
					{
						"label": "St. John's (UTC-3:30)",
						"value": "12",
					},
					{
						"label": "Rio De Janeiro (UTC-3)",
						"value": "13",
					},
					{
						"label": "F. de Noronha (UTC-2)",
						"value": "14",
					},
					{
						"label": "Praia (UTC-1)",
						"value": "15",
					},
					{
						"label": "UTC (UTC+0)",
						"value": "16",
					},
					{
						"label": "Lisbon (UTC+0)",
						"value": "17",
					},
					{
						"label": "London (UTC+0)",
						"value": "18",
					},
					{
						"label": "Madrid (UTC+1)",
						"value": "19",
					},
					{
						"label": "Paris (UTC+1)",
						"value": "20",
					},
					{
						"label": "Rome (UTC+1)",
						"value": "21",
					},
					{
						"label": "Berlin (UTC+1)",
						"value": "22",
					},
					{
						"label": "Stockholm (UTC+1)",
						"value": "23",
					},
					{
						"label": "Athens (UTC+2)",
						"value": "24",
					},
					{
						"label": "Cairo (UTC+2)",
						"value": "25",
					},
					{
						"label": "Jerusalem (UTC+2)",
						"value": "26",
					},
					{
						"label": "Moscow (UTC+3)",
						"value": "27",
					},
					{
						"label": "Jeddah (UTC+3)",
						"value": "28",
					},
					{
						"label": "Tehran (UTC+3:30)",
						"value": "29",
					},
					{
						"label": "Dubai (UTC+4)",
						"value": "30",
					},
					{
						"label": "Kabul (UTC+4:30)",
						"value": "31",
					},
					{
						"label": "Karachi (UTC+5)",
						"value": "32",
					},
					{
						"label": "Delhi (UTC+5:30)",
						"value": "33",
					},
					{
						"label": "Kathmandu (UTC+5:45)",
						"value": "34",
					},
					{
						"label": "Dhaka (UTC+6)",
						"value": "35",
					},
					{
						"label": "Yangon (UTC+6:30)",
						"value": "36",
					},
					{
						"label": "Bangkok (UTC+7)",
						"value": "37",
					},
					{
						"label": "Singapore (UTC+8)",
						"value": "38",
					},
					{
						"label": "Hong Kong (UTC+8)",
						"value": "39",
					},
					{
						"label": "Beijing (UTC+8)",
						"value": "40",
					},
					{
						"label": "Taipei (UTC+8)",
						"value": "41",
					},
					{
						"label": "Seoul (UTC+9)",
						"value": "42",
					},
					{
						"label": "Tokyo (UTC+9)",
						"value": "43",
					},
					{
						"label": "Adelaide (UTC+9:30)",
						"value": "44",
					},
					{
						"label": "Guam (UTC+10)",
						"value": "45",
					},
					{
						"label": "Sydney (UTC+10)",
						"value": "46",
					},
					{
						"label": "Noumea (UTC+11)",
						"value": "47",
					},
					{
						"label": "Wellington (UTC+12)",
						"value": "48",
					},
				],
			},
		],
	},
	{
		"type": "submit",
		"defaultValue": "Save Settings",
	},
];
