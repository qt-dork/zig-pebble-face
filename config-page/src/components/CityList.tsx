import React from 'react';
import { Switch } from 'react-aria-components';
import { FormItemLabel } from './FormItem';
import { City } from '../data/cities';
import { formatOffset } from '../utils/string';

const PinIcon = ({ filled }: { filled: boolean }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    height="20px"
    viewBox="0 -960 960 960"
    width="20px"
    fill="currentColor"
  >
    {filled ? (
      <path d="m233-120 65-281L80-590l288-25 112-265 112 265 288 25-218 189 65 281-247-149-247 149Z" />
    ) : (
      <path d="m354-287 126-76 126 77-33-144 111-96-146-13-58-136-58 135-146 13 111 97-33 143ZM233-120l65-281L80-590l288-25 112-265 112 265 288 25-218 189 65 281-247-149-247 149Zm247-350Z" />
    )}
  </svg>
);

export const CityList: React.FC<{
  title?: string;
  titleCount?: string;
  cities: City[];
  pinnedCities: string[];
  onToggle: (cityName: string) => void;
  disablePinning?: boolean;
  actionLabel?: string;
  onAction?: () => void;
  children?: React.ReactNode;
  footer?: React.ReactNode;
  emptyStateMessage?: string;
}> = ({ title, titleCount, cities, pinnedCities, onToggle, disablePinning, actionLabel, onAction, children, footer, emptyStateMessage }) => {
  return (
    <div className="city-list-section">
      {(title || (actionLabel && onAction)) && (
        <div className="city-list-header">
          {title && (
            <h3>
              {title}
              {titleCount && <span className="city-list-count">{titleCount}</span>}
            </h3>
          )}
          {actionLabel && onAction && (
            <button className="halite-text-button" onClick={onAction}>
              {actionLabel}
            </button>
          )}
        </div>
      )}
      <div className="city-list">
        {children}
        {cities.length === 0 && emptyStateMessage && (
          <div className="city-item empty-state">
            <span className="halite-description">{emptyStateMessage}</span>
          </div>
        )}
        {cities.map((city) => {
          const isPinned = pinnedCities.includes(city.name);
          return (
            <div key={city.name} className="city-item">
              <Switch
                isSelected={isPinned}
                onChange={() => onToggle(city.name)}
                isDisabled={disablePinning && !isPinned}
                className="city-toggle"
              >
                <div className="city-toggle-content">
                  <div className={`city-pin-icon ${isPinned ? 'pinned' : ''}`}>
                    <PinIcon filled={isPinned} />
                  </div>
                  <FormItemLabel 
                    label={city.displayName} 
                    description={formatOffset(city.offset)}
                  />
                </div>
              </Switch>
            </div>
          );
        })}
        {footer}
      </div>
    </div>
  );
};