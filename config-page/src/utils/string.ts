export const formatOffset = (minutes: number): string => {
  const hours = Math.floor(Math.abs(minutes) / 60);
  const mins = Math.abs(minutes) % 60;
  const sign = minutes >= 0 ? '+' : '-';
  const timeStr = mins === 0 ? `${hours}` : `${hours}:${mins.toString().padStart(2, '0')}`;
  return `UTC${sign}${timeStr}`;
};
