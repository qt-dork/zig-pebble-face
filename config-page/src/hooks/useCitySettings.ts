import React from 'react';
import { useConfig } from '../context/PebbleConfigContext';
import { CITIES } from '../data/cities';
import type { CustomCity } from '../data/cities';

const MAX_CITIES = 50;

function parseJsonArray<T>(raw: string | undefined): T[] {
  try {
    return JSON.parse(raw || '[]');
  } catch {
    return [];
  }
}

export function useCitySettings() {
  const { settings, updateSetting } = useConfig();

  const pinnedCities: string[] = React.useMemo(
    () => parseJsonArray(settings.SETTING_PINNED_CITIES),
    [settings.SETTING_PINNED_CITIES],
  );

  const customCities: CustomCity[] = React.useMemo(
    () => parseJsonArray(settings.SETTING_CUSTOM_CITIES),
    [settings.SETTING_CUSTOM_CITIES],
  );

  // Current location always occupies one slot
  const totalCities = 1 + pinnedCities.length + customCities.length;
  const atLimit = totalCities >= MAX_CITIES;
  const remainingSlots = MAX_CITIES - totalCities;

  const pinnedCityList = React.useMemo(
    () => CITIES.filter(city => pinnedCities.includes(city.name)),
    [pinnedCities],
  );

  const unpinnedCityList = React.useMemo(
    () => CITIES.filter(city => !pinnedCities.includes(city.name)),
    [pinnedCities],
  );

  const toggleCity = React.useCallback((cityName: string) => {
    const isCurrentlyPinned = pinnedCities.includes(cityName);
    if (!isCurrentlyPinned && atLimit) return;
    const next = isCurrentlyPinned
      ? pinnedCities.filter((name: string) => name !== cityName)
      : [...pinnedCities, cityName];
    updateSetting('SETTING_PINNED_CITIES', JSON.stringify(next));
  }, [pinnedCities, atLimit, updateSetting]);

  const pinAll = React.useCallback(() => {
    updateSetting('SETTING_PINNED_CITIES', JSON.stringify(CITIES.map(c => c.name)));
  }, [updateSetting]);

  const unpinAll = React.useCallback(() => {
    updateSetting('SETTING_PINNED_CITIES', JSON.stringify([]));
  }, [updateSetting]);

  const addCustomCity = React.useCallback((city: CustomCity) => {
    if (atLimit) return;
    updateSetting('SETTING_CUSTOM_CITIES', JSON.stringify([...customCities, city]));
  }, [customCities, atLimit, updateSetting]);

  const deleteCustomCity = React.useCallback((index: number) => {
    updateSetting('SETTING_CUSTOM_CITIES', JSON.stringify(customCities.filter((_, i) => i !== index)));
  }, [customCities, updateSetting]);

  return {
    pinnedCities,
    customCities,
    pinnedCityList,
    unpinnedCityList,
    totalCities,
    maxCities: MAX_CITIES,
    atLimit,
    remainingSlots,
    toggleCity,
    pinAll,
    unpinAll,
    addCustomCity,
    deleteCustomCity,
  };
}
