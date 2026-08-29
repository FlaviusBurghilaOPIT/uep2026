import { describe, it, expect } from 'vitest'
import {
  FREQUENCY_SCHEDULES,
  VALID_FREQUENCIES,
  getFrequencySchedule,
  getScheduleTimesForCode,
  isValidFrequency,
  formatTime12h,
  type FrequencyCode
} from '../utils/medicationSchedule'

describe('Medication Clinical Schedule Picker & Norman Constraints', () => {
  it('defines all required clinical frequency codes', () => {
    expect(VALID_FREQUENCIES).toEqual(['QD', 'BID', 'TID', 'QID', 'PRN'])
  })

  it('correctly maps QD (Once Daily) to standardized 08:00 slot', () => {
    const qd = getFrequencySchedule('QD')
    expect(qd.code).toBe('QD')
    expect(qd.dosesPerDay).toBe(1)
    expect(qd.times).toEqual(['08:00'])
    expect(getScheduleTimesForCode('QD')).toEqual(['08:00'])
  })

  it('correctly maps BID (Twice Daily) to standardized 08:00 and 20:00 slots', () => {
    const bid = getFrequencySchedule('BID')
    expect(bid.code).toBe('BID')
    expect(bid.dosesPerDay).toBe(2)
    expect(bid.times).toEqual(['08:00', '20:00'])
    expect(getScheduleTimesForCode('BID')).toEqual(['08:00', '20:00'])
  })

  it('correctly maps TID (Three Times Daily) to standardized 08:00, 13:00, 20:00 slots', () => {
    const tid = getFrequencySchedule('TID')
    expect(tid.code).toBe('TID')
    expect(tid.dosesPerDay).toBe(3)
    expect(tid.times).toEqual(['08:00', '13:00', '20:00'])
    expect(getScheduleTimesForCode('TID')).toEqual(['08:00', '13:00', '20:00'])
  })

  it('correctly maps QID (Four Times Daily) to standardized 08:00, 12:00, 16:00, 20:00 slots', () => {
    const qid = getFrequencySchedule('QID')
    expect(qid.code).toBe('QID')
    expect(qid.dosesPerDay).toBe(4)
    expect(qid.times).toEqual(['08:00', '12:00', '16:00', '20:00'])
    expect(getScheduleTimesForCode('QID')).toEqual(['08:00', '12:00', '16:00', '20:00'])
  })

  it('correctly maps PRN (As Needed) to empty slot times list', () => {
    const prn = getFrequencySchedule('PRN')
    expect(prn.code).toBe('PRN')
    expect(prn.dosesPerDay).toBe(0)
    expect(prn.times).toEqual([])
    expect(getScheduleTimesForCode('PRN')).toEqual([])
  })

  it('handles case-insensitive and fallback lookups gracefully', () => {
    expect(getFrequencySchedule('bid').code).toBe('BID')
    expect(getFrequencySchedule('tid').times).toEqual(['08:00', '13:00', '20:00'])
    expect(getFrequencySchedule(null).code).toBe('QD')
    expect(getFrequencySchedule('UNKNOWN').code).toBe('QD')
  })

  it('validates frequency codes correctly', () => {
    expect(isValidFrequency('QD')).toBe(true)
    expect(isValidFrequency('bid')).toBe(true)
    expect(isValidFrequency('TID')).toBe(true)
    expect(isValidFrequency('qid')).toBe(true)
    expect(isValidFrequency('PRN')).toBe(true)
    expect(isValidFrequency('twice a day')).toBe(false)
    expect(isValidFrequency('every 4 hours')).toBe(false)
    expect(isValidFrequency(123)).toBe(false)
    expect(isValidFrequency(null)).toBe(false)
  })

  it('formats 24-hour time strings to 12-hour AM/PM correctly', () => {
    expect(formatTime12h('08:00')).toBe('8:00 AM')
    expect(formatTime12h('12:00')).toBe('12:00 PM')
    expect(formatTime12h('13:00')).toBe('1:00 PM')
    expect(formatTime12h('16:00')).toBe('4:00 PM')
    expect(formatTime12h('20:00')).toBe('8:00 PM')
    expect(formatTime12h('00:00')).toBe('12:00 AM')
    expect(formatTime12h('invalid')).toBe('invalid')
  })
})
