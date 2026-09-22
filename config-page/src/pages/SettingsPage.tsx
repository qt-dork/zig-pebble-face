import React from 'react';
import { Page, Section, Select } from '../components';
import { CITIES } from '../data/cities';
import { formatOffset } from '../utils/string';

export const SettingsPage: React.FC = () => {
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

      <Section title="Time Zone">
        <Select
          label="Time zone to track"
          description="Shown on the world map and in the corner clock."
          messageKey="SETTING_TIME_ZONE"
          options={[
            { label: 'Local time', value: -1 },
            ...CITIES.map((city, index) => ({
              label: `${city.displayName} (${formatOffset(city.offset)})`,
              value: index,
            })),
          ]}
        />
      </Section>
    </Page>
  );
};
