/**
 * Constrained Clinical Schedule Picker Helpers (Norman Constraints)
 * Prevents prescription scheduling syntax errors by mapping standard frequency codes
 * (QD, BID, TID, QID, PRN) to structured, standardized daily dose time slots.
 */

export type FrequencyCode = 'QD' | 'BID' | 'TID' | 'QID' | 'PRN'

export interface FrequencyOption {
  code: FrequencyCode
  label: string
  shortLabel: string
  dosesPerDay: number
  times: string[]
  timeLabels: string[]
  description: string
  badgeClass: string
}

export const FREQUENCY_SCHEDULES: Record<FrequencyCode, FrequencyOption> = {
  QD: {
    code: 'QD',
    label: 'Once Daily (QD)',
    shortLabel: 'QD',
    dosesPerDay: 1,
    times: ['08:00'],
    timeLabels: ['Morning (08:00 AM)'],
    description: '1 dose per day at 08:00 AM',
    badgeClass: 'badge-qd'
  },
  BID: {
    code: 'BID',
    label: 'Twice Daily (BID)',
    shortLabel: 'BID',
    dosesPerDay: 2,
    times: ['08:00', '20:00'],
    timeLabels: ['Morning (08:00 AM)', 'Evening (08:00 PM)'],
    description: '2 doses per day at 08:00 AM & 08:00 PM',
    badgeClass: 'badge-bid'
  },
  TID: {
    code: 'TID',
    label: 'Three Times Daily (TID)',
    shortLabel: 'TID',
    dosesPerDay: 3,
    times: ['08:00', '13:00', '20:00'],
    timeLabels: ['Morning (08:00 AM)', 'Midday (01:00 PM)', 'Evening (08:00 PM)'],
    description: '3 doses per day at 08:00 AM, 01:00 PM & 08:00 PM',
    badgeClass: 'badge-tid'
  },
  QID: {
    code: 'QID',
    label: 'Four Times Daily (QID)',
    shortLabel: 'QID',
    dosesPerDay: 4,
    times: ['08:00', '12:00', '16:00', '20:00'],
    timeLabels: ['Morning (08:00 AM)', 'Midday (12:00 PM)', 'Afternoon (04:00 PM)', 'Night (08:00 PM)'],
    description: '4 doses per day (every 4–6 waking hours)',
    badgeClass: 'badge-qid'
  },
  PRN: {
    code: 'PRN',
    label: 'As Needed (PRN)',
    shortLabel: 'PRN',
    dosesPerDay: 0,
    times: [],
    timeLabels: [],
    description: 'As needed on-demand (no fixed scheduled slot times)',
    badgeClass: 'badge-prn'
  }
}

export const VALID_FREQUENCIES: FrequencyCode[] = ['QD', 'BID', 'TID', 'QID', 'PRN']

export function isValidFrequency(code: unknown): code is FrequencyCode {
  return typeof code === 'string' && VALID_FREQUENCIES.includes(code.toUpperCase() as FrequencyCode)
}

export function getFrequencySchedule(code: string | undefined | null): FrequencyOption {
  if (!code) return FREQUENCY_SCHEDULES.QD
  const upper = code.toUpperCase() as FrequencyCode
  return FREQUENCY_SCHEDULES[upper] || FREQUENCY_SCHEDULES.QD
}

export function getScheduleTimesForCode(code: string | undefined | null): string[] {
  return getFrequencySchedule(code).times
}

export function formatTime12h(time24: string): string {
  if (!time24 || !time24.includes(':')) return time24
  const [hourStr, minStr] = time24.split(':')
  const hour = parseInt(hourStr, 10)
  const minutes = minStr || '00'
  if (isNaN(hour)) return time24
  const period = hour >= 12 ? 'PM' : 'AM'
  const hour12 = hour % 12 === 0 ? 12 : hour % 12
  return `${hour12}:${minutes.padStart(2, '0')} ${period}`
}
