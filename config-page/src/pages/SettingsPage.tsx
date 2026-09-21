import React from 'react';
import { Page, Section, Select, CityList, FormItemLabel, CustomCitiesSection } from '../components';
import { LocationArrowIcon } from '../components/icons';
import { useCitySettings } from '../hooks/useCitySettings';

export const SettingsPage: React.FC = () => {
  const {
    pinnedCities,
    customCities,
    pinnedCityList,
    unpinnedCityList,
    totalCities,
    maxCities,
    atLimit,
    remainingSlots,
    toggleCity,
    pinAll,
    unpinAll,
    addCustomCity,
    deleteCustomCity,
  } = useCitySettings();

  console.log(pinnedCities);
  console.log(pinnedCityList);

  return (
    <Page title="Royale Settings">
      <Section title="General">
        <Select
          label="Screen update frequency"
          description="More frequent is worse for battery"
          messageKey="SETTING_ENABLE_SECONDS"
          options={[
            { label: 'Per second', value: 0 },
            { label: 'Per 15 seconds', value: 1 },
            { label: 'Per minute', value: 2 },
          ]}
        />
        <Select
          label="Date format"
          description="Displayed above the current time"
          messageKey="SETTING_DATE_FORMAT"
          options={[
            { label: 'MM-DD', value: 0 },
            { label: 'DD-MM', value: 1 },
          ]}
        />
      </Section>

      <Section title="Time Zones">
        <Select
          label="Current time zone"
          description="Displayed in the analogue clock in the corner"
          messageKey="SETTING_TIME_ZONE"
          options={pinnedCityList.map(
            (city, i) => ({ label: city.displayName, value: i })
          )}
        />
        <CityList
          title="Your Cities"
          titleCount={`${totalCities}/${maxCities}`}
          cities={pinnedCityList}
          pinnedCities={pinnedCities}
          onToggle={toggleCity}
          actionLabel="Unpin All"
          onAction={pinnedCityList.length > 0 ? unpinAll : undefined}
          footer={
            <CustomCitiesSection
              customCities={customCities}
              onAdd={addCustomCity}
              onDelete={deleteCustomCity}
              disableAdd={atLimit}
            />
          }
        >
          <div className="city-item">
            <div className="city-toggle-content">
              <div className="city-pin-icon neutral">
                <LocationArrowIcon />
              </div>
              <FormItemLabel label="Current Location" description="Always shown" />
            </div>
          </div>
        </CityList>
        <CityList
          title="Available Cities"
          cities={unpinnedCityList}
          pinnedCities={pinnedCities}
          onToggle={toggleCity}
          disablePinning={atLimit}
          actionLabel="Pin All"
          onAction={unpinnedCityList.length > 0 && unpinnedCityList.length <= remainingSlots ? pinAll : undefined}
          emptyStateMessage="All available cities pinned; the true Casio™ World Time experience!"
        />
      </Section>
    </Page>
  );
};
