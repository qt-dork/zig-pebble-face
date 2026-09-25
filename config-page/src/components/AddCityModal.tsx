import React from 'react';
import {
  Modal,
  ModalOverlay,
  Dialog,
  Button,
  Heading,
  Autocomplete,
  SearchField,
  Input,
  ListBox,
  ListBoxItem,
  useAsyncList,
} from 'react-aria-components';
import { CITIES } from '../data/cities';
import type { CustomCity } from '../data/cities';
import { formatOffset } from '../utils/string';
import { GeolocateIcon } from './icons';

const MAX_NAME_LENGTH = 15;

const guessTzCityFromLon = (lon: number): string => {
  const estimatedOffsetMinutes = Math.round(lon / 15) * 60;
  return CITIES.reduce((best, city) =>
    Math.abs(city.offset - estimatedOffsetMinutes) < Math.abs(best.offset - estimatedOffsetMinutes)
      ? city
      : best
  ).name;
};

interface NominatimAddress {
  city?: string;
  town?: string;
  village?: string;
  municipality?: string;
}

interface NominatimResult {
  place_id: number;
  display_name: string;
  lat: string;
  lon: string;
  address?: NominatimAddress;
}

interface AddCityModalProps {
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
  onAdd: (city: CustomCity) => void;
}

export const AddCityModal: React.FC<AddCityModalProps> = ({ isOpen, onOpenChange, onAdd }) => {
  const [cityName, setCityName] = React.useState('');
  const [lat, setLat] = React.useState<number | null>(null);
  const [lon, setLon] = React.useState<number | null>(null);
  const [tzCityName, setTzCityName] = React.useState('UTC');
  const [geoLoading, setGeoLoading] = React.useState(false);
  const [geoError, setGeoError] = React.useState(false);
  // 'none' | 'geo' | 'search' — tracks how the location was set
  const [locationSource, setLocationSource] = React.useState<'none' | 'geo' | 'search'>('none');
  // Prevents a spurious load when we programmatically set filterText after selection
  const justSelectedRef = React.useRef(false);

  const list = useAsyncList<NominatimResult>({
    async load({ signal, filterText }) {
      if (!filterText?.trim() || justSelectedRef.current) {
        justSelectedRef.current = false;
        return { items: [] };
      }
      // Debounce: bail out if aborted before the delay expires
      await new Promise(r => setTimeout(r, 300));
      if (signal.aborted) return { items: [] };
      try {
        const res = await fetch(
          `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(filterText)}&format=json&limit=5&addressdetails=1&accept-language=en`,
          { signal },
        );
        const data: NominatimResult[] = await res.json();
        return { items: data };
      } catch {
        return { items: [] };
      }
    },
  });

  const resetForm = () => {
    setCityName('');
    setLat(null);
    setLon(null);
    setTzCityName('UTC');
    setGeoLoading(false);
    setGeoError(false);
    setLocationSource('none');
    list.setFilterText('');
  };

  const resetLocation = () => {
    setLat(null);
    setLon(null);
    setTzCityName('UTC');
    setGeoLoading(false);
    setGeoError(false);
    setLocationSource('none');
    justSelectedRef.current = false;
    list.setFilterText('');
  };

  const handleSelect = (key: React.Key) => {
    const result = list.items.find(s => String(s.place_id) === String(key));
    if (!result) return;

    const parsedLat = parseFloat(result.lat);
    const parsedLon = parseFloat(result.lon);
    setLat(parsedLat);
    setLon(parsedLon);
    setTzCityName(guessTzCityFromLon(parsedLon));

    const addr = result.address;
    const shortName = (
      addr?.city || addr?.town || addr?.village || addr?.municipality || result.display_name.split(',')[0]
    ).trim().slice(0, MAX_NAME_LENGTH);
    setCityName(shortName);

    // Show concise label in the input without triggering another search
    justSelectedRef.current = true;
    const parts = result.display_name.split(',').map(s => s.trim());
    list.setFilterText(parts.slice(0, 2).join(', '));
    setLocationSource('search');
  };

  const handleUseLocation = () => {
    setGeoLoading(true);
    setGeoError(false);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLat(pos.coords.latitude);
        setLon(pos.coords.longitude);
        setTzCityName(guessTzCityFromLon(pos.coords.longitude));
        setLocationSource('geo');
        setGeoLoading(false);
      },
      () => {
        setGeoError(true);
        setGeoLoading(false);
      },
      { timeout: 8000, maximumAge: 60000 },
    );
  };

  const handleAdd = () => {
    if (!cityName.trim() || lat === null || lon === null) return;
    onAdd({ displayName: cityName.trim(), lat, lon, tzCityName });
    resetForm();
    onOpenChange(false);
  };

  const canAdd = cityName.trim().length > 0 && lat !== null && lon !== null;
  const showSuggestions =
    (list.isLoading || list.items.length > 0) && list.filterText.trim().length > 0;

  return (
    <ModalOverlay
      isOpen={isOpen}
      onOpenChange={(open) => {
        if (!open) resetForm();
        onOpenChange(open);
      }}
      className="halite-modal-overlay"
    >
      <Modal className="halite-modal halite-add-city-modal">
        <Dialog className="halite-dialog">
          {({ close }) => (
            <>
              <div className="halite-modal-header">
                <Heading slot="title">Add Custom City</Heading>
                <Button
                  className="halite-modal-close"
                  onPress={() => { resetForm(); close(); }}
                >
                  ×
                </Button>
              </div>

              <div className="halite-add-city-content">
                <div className="halite-add-city-field">
                  <label className="halite-add-city-label">Location</label>

                  {locationSource === 'geo' ? (
                    /* Geo confirmed — show a pill that looks like the input */
                    <div className="halite-add-city-confirmed">
                      <GeolocateIcon />
                      <span>Current location</span>
                      <button
                        className="halite-add-city-confirmed-clear"
                        aria-label="Clear location"
                        onClick={resetLocation}
                      >
                        ×
                      </button>
                    </div>
                  ) : locationSource === 'search' ? (
                    /* Search confirmed — show a pill with the selected place name */
                    <div className="halite-add-city-confirmed">
                      <span>{list.filterText}</span>
                      <button
                        className="halite-add-city-confirmed-clear"
                        aria-label="Clear location"
                        onClick={resetLocation}
                      >
                        ×
                      </button>
                    </div>
                  ) : (
                    /* Search box */
                    <div className="halite-add-city-combobox">
                      <Autocomplete inputValue={list.filterText} onInputChange={list.setFilterText}>
                        <SearchField
                          aria-label="Search for a location"
                          className="halite-add-city-search-field"
                        >
                          <Input
                            className="halite-input"
                            placeholder="Search for a city…"
                            autoComplete="off"
                          />
                        </SearchField>
                        <ListBox
                          items={list.items}
                          aria-label="Location suggestions"
                          onAction={handleSelect}
                          data-open={showSuggestions || undefined}
                          className="halite-combobox-popover halite-combobox-listbox"
                          renderEmptyState={() => list.isLoading
                            ? <span className="halite-combobox-item halite-combobox-item-status">Searching…</span>
                            : null
                          }
                        >
                          {(item) => (
                            <ListBoxItem
                              id={String(item.place_id)}
                              textValue={item.display_name}
                              className="halite-combobox-item"
                            >
                              {item.display_name}
                            </ListBoxItem>
                          )}
                        </ListBox>
                      </Autocomplete>
                    </div>
                  )}

                  {/* Use my location button — hidden once any location is set */}
                  {locationSource === 'none' && navigator.geolocation && (
                    <>
                      <div className="halite-add-city-divider">or</div>
                      <Button
                        className="halite-add-city-location-btn"
                        isDisabled={geoLoading}
                        onPress={handleUseLocation}
                      >
                        <GeolocateIcon />
                        {geoLoading ? 'Locating…' : 'Use my location'}
                      </Button>
                    </>

                  )}

                  {geoError && (
                    <p className="halite-add-city-geo-result halite-import-error">
                      Could not get location. Please try again.
                    </p>
                  )}
                </div>

                <div className="halite-add-city-field">
                  <div className="halite-add-city-label-row">
                    <label className="halite-add-city-label" htmlFor="add-city-name">
                      Name on watch
                    </label>
                    <span className="halite-add-city-counter">
                      {cityName.length}/{MAX_NAME_LENGTH}
                    </span>
                  </div>
                  <input
                    id="add-city-name"
                    className="halite-input"
                    type="text"
                    maxLength={MAX_NAME_LENGTH}
                    value={cityName}
                    onChange={(e) => setCityName(e.target.value)}
                  />
                </div>

                <div className="halite-add-city-field">
                  <label className="halite-add-city-label" htmlFor="add-city-tz">
                    Time zone
                  </label>
                  <select
                    id="add-city-tz"
                    value={tzCityName}
                    onChange={(e) => setTzCityName(e.target.value)}
                  >
                    {CITIES.map((city) => (
                      <option key={city.name} value={city.name}>
                        {city.timezone} ({formatOffset(city.offset)})
                      </option>
                    ))}
                  </select>
                </div>

                <Button
                  className="halite-import-button halite-add-city-add-btn"
                  isDisabled={!canAdd}
                  onPress={handleAdd}
                >
                  Add City
                </Button>
              </div>
            </>
          )}
        </Dialog>
      </Modal>
    </ModalOverlay >
  );
};
