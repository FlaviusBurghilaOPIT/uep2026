export type Language = 'en' | 'es' | 'it'

export interface NavTranslations {
  triageDashboard: string
  patients: string
  newCase: string
  medications: string
  recommendations: string
  fdaSafety: string
  logout: string
  clinicianRole: string
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
  allAlerts: string
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
  errorLoading: string
  noLogsYet: string
  dataUnknown: string
  lastUpdated: string
  refresh: string
  allOnTrack: string
  resolveFailed: string
  resolvedToast: string
  noPhone: string
  reviewCase: string
  resolveException: string
  callPatient: string
  stable: string
  surgery: string
  triggerReasons: string
  noteRequired: string
  outreachPhone: string
  outreachSms: string
  outreachVisit: string
  archiving: string
  adherenceLabel: string
  reasonMissed: string
  reasonAiEscalation: string
  reasonSideEffects: string
  reasonLowAdherence: string
  unknownTitle: string
  unknownTelemetry: string
  medianResponse: string
  noResponseData: string
  responseTarget: string
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
  retry: string
  errorLoading: string
}

export interface MedicationTranslations {

  errorMissingFields: string
  errorAddFailed: string
  successTitle: string
  successSubtitle: string
  viewAll: string
  backToPatients: string
  title: string
  caseSubtitle: string
  drugName: string
  drugNamePlaceholder: string
  viewFdaSafety: string
  viewOnFdaWebsite: string
  dose: string
  dosePlaceholder: string
  durationDays: string
  durationPlaceholder: string
  notesOptional: string
  notesPlaceholder: string
  adding: string
  addMedication: string
  cancel: string

  frequencyLabel:   string
  frequencyQD:      string
  frequencyBID:     string
  frequencyTID:     string
  frequencyQID:     string
  frequencyPRN:     string
  remindersAt:      string
  noReminders:      string
}


export interface LoginTranslations {
  title: string
  subtitle: string
  emailPlaceholder: string
  passwordPlaceholder: string
  errorInvalid: string
  button: string
  loggingIn: string
}

export interface AuthTranslations {
  sessionExpired: string
}

export interface CreateCaseTranslations {
  errorMissingFields: string
  errorCreateFailed: string
  successTitle: string
  successSubtitle: string
  prescribeMedications: string
  addRecommendations: string
  backToPatients: string
  title: string
  selectPatient: string
  selectPatientPlaceholder: string
  surgeryType: string
  surgeryTypePlaceholder: string
  creating: string
  createCase: string
  cancel: string
  errorLoadPatients: string
}

export interface CreatePatientTranslations {
  errorMissingFields: string
  errorInviteFailed: string
  successTitle: string
  successSubtitle: string
  inviteLabel: string
  inviteSubtext: string
  backToPatients: string
  title: string
  fullName: string
  fullNamePlaceholder: string
  email: string
  emailPlaceholder: string
  dateOfBirth: string
  dateOfBirthPlaceholder: string
  surgeryType: string
  surgeryTypePlaceholder: string
  surgeryDate: string
  surgeryDatePlaceholder: string
  emergencyContact: string
  emergencyContactPlaceholder: string
  inviting: string
  invitePatient: string
  cancel: string
}

export interface FdaTranslations {
  errorMissingDrug: string
  errorFetchFailed: string
  title: string
  subtitle: string
  searchPlaceholder: string
  searching: string
  search: string
  retrieved: string
  viewOnFDAWebsite: string
  warningsTitle: string
  disclaimer: string
  fetching: string
  emptyText: string
  searchLabel: string
  noWarnings: string
}

export interface PatientsTranslations {
  title: string
  newPatient: string
  loading: string
  dob: string
  allergies: string
  none: string
  exportCsv: string
  printPdf: string
  newCase: string
  pendingOnboarding: string
  copied: string
  copyCode: string
  cases: string
  medications: string
  recommendations: string
  noCases: string
  emptyTitle: string
  emptyBody: string
}

export interface MedicationsListTranslations {
  title: string
  case: string
  addMedication: string
  loading: string
  empty: string
  dose: string
  duration: string
  days: string
  viewFdaSafety: string
  backToPatients: string
}

export interface RecommendationsListTranslations {
  title: string
  case: string
  addRecommendation: string
  loading: string
  added: string
  backToPatients: string
  empty: string
}

export interface RecommendationsTranslations {
  aiGreeting: string
  errorMissingContent: string
  errorSaveFailed: string
  aiError: string
  successTitle: string
  successSubtitle: string
  viewAll: string
  backToPatients: string
  title: string
  caseSubtitle: string
  instructionsLabel: string
  instructionsPlaceholder: string
  askAiTitle: string
  aiTitle: string
  aiSubtitle: string
  useSuggestion: string
  thinking: string
  chatPlaceholder: string
  send: string
  saving: string
  saveRecommendations: string
  cancel: string
}

export interface CaseDetailTranslations {
  title: string
  backToPatients: string
  emergencyContact: string
  adherenceTimeline: string
  colMedication: string
  colScheduled: string
  colStatus: string
  colLogged: string
  noDoseLogs: string
  symptomTrend: string
  noCheckins: string
  feelingGreat: string
  feelingOk: string
  feelingNotGreat: string
  feelingBad: string
  prescriptions: string
  recoveryInstructions: string
  manageMedications: string
  manageRecommendations: string
  statusTaken: string
  statusMissed: string
  statusSkipped: string
  statusPending: string
  caseNotFound: string
}

export interface Translations {

  login: LoginTranslations
  auth: AuthTranslations
  createCase: CreateCaseTranslations
  createPatient: CreatePatientTranslations
  fda: FdaTranslations
  patients: PatientsTranslations
  medicationsList: MedicationsListTranslations
  recommendationsList: RecommendationsListTranslations
  recommendations: RecommendationsTranslations

  caseDetail: CaseDetailTranslations
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
