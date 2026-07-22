export type Language = 'en' | 'es' | 'it'

export interface NavTranslations {
  triageDashboard: string
  patients: string
  newCase: string
  medications: string
  recommendations: string
  fdaSafety: string
  logout: string
}

export interface TriageTranslations {
  title: string
  subtitle: string
  highPriority: string
  mediumPriority: string
  lowPriority: string
  activeCases: string
  quickStats: string
  emergencyTriage: string
  allPatients: string
  redAlerts: string
  amberAlerts: string
  searchPlaceholder: string
  noPatientsFound: string
  loadingTriage: string
  adherenceRate: string
  missedDoses: string
  riskScore: string
  status: string
  actionNeeded: string
  escalationReasons: string
  resolveModalTitle: string
  outreachMethod: string
  clinicalNote: string
  notePlaceholder: string
}

export interface PatientCardTranslations {
  age: string
  gender: string
  primaryCondition: string
  vitals: string
  symptoms: string
  riskScore: string
  status: string
  contact: string
  action: string
  viewCase: string
  missedDoses: string
  adherence: string
  escalationReason: string
  outreach: string
  resolve: string
  phone: string
  email: string
  allergies: string
  surgeryType: string
  lastCheckin: string
}

export interface CtaTranslations {
  createCase: string
  addPatient: string
  save: string
  cancel: string
  filter: string
  refresh: string
  search: string
  viewDetails: string
  export: string
  confirm: string
  resolveTriage: string
  resolveCase: string
  logout: string
  submit: string
  close: string
}

export interface CommonTranslations {
  language: string
  selectLanguage: string
  english: string
  spanish: string
  italian: string
  loading: string
  error: string
  success: string
}

export interface MedicationTranslations {
  frequencyLabel:   string
  frequencyQD:      string
  frequencyBID:     string
  frequencyTID:     string
  frequencyQID:     string
  frequencyPRN:     string
  remindersAt:      string
  noReminders:      string
}

export interface Translations {
  nav: NavTranslations
  triage: TriageTranslations
  patientCard: PatientCardTranslations
  cta: CtaTranslations
  common: CommonTranslations
  medication: MedicationTranslations
}

export interface LanguageContextType {
  language: Language
  setLanguage: (lang: Language) => void
  t: (path: string, fallback?: string) => string
  translations: Translations
}
