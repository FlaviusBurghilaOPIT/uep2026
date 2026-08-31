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
  sectionTriage?: string
  sectionCare?: string
  sectionSafety?: string
  telemetryConnected?: string
  liveBadge?: string
  language?: string
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
  aiSummary?: string
  aiSummaryTitle?: string
  liveConnected?: string
  queueTitle?: string
  stableRosterTitle?: string
  statusStable?: string
  tabAll?: string
  tabRed?: string
  tabAmber?: string
  reasonSeverePain?: string
  reasonDiscomfort?: string
  aiSummarySubtitle?: string
  aiEngineBadge?: string
  statSubRed?: string
  statSubRedClean?: string
  statSubAmber?: string
  statSubAmberClean?: string
  statSubBlue?: string
  queueSubtitle?: string
  emptyTitle?: string
  criticalException?: string
  moderateAttention?: string
  escalationTriggers?: string
  stableSubtitle?: string
  noResults?: string
  trendWorse?: string
  trendWorseTitle?: string
  trendBetter?: string
  trendBetterTitle?: string
  moreReasons?: string
  acknowledge?: string
  acknowledgedLabel?: string
  viewDetails?: string
  toggleStableRoster?: string
  mostUrgent?: string
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
  scheduledTimesLabel: string
  doseSlot:         string
  prnHelpText:      string
}


export interface LandingTranslations {
  badge: string
  headline: string
  headlineHighlight: string
  subheadline: string
  launchDemo: string
  exploreFeatures: string
  loginLink: string
  trustTrack: string
  trustGuardrails: string
  trustFda: string
  problemTitle: string
  problemSubtitle: string
  traditionalTitle: string
  traditionalDesc: string
  traditional1: string
  traditional2: string
  traditional3: string
  platformTitle: string
  platformDesc: string
  platform1: string
  platform2: string
  platform3: string
  feature1Title: string
  feature1Desc: string
  feature1Badge: string
  feature2Title: string
  feature2Desc: string
  feature2Badge: string
  feature3Title: string
  feature3Desc: string
  feature3Badge: string
  featuresSectionHeading: string
  featuresSectionSubheading: string
  previewTitle: string
  previewSubtitle: string
  previewSimulateAlert: string
  previewResolvedAlert: string
  previewLiveBadge: string
  telemetryPrescribedLabel: string
  telemetryAdherenceLabel: string
  telemetryOxycodone: string
  telemetryMissedMorning: string
  telemetryGoodStatus: string
  telemetryInitiatingOutreach: string
  telemetrySimulateOutreach: string
  telemetryOutreachLogged: string
  timelineTitle: string
  step1Num: string
  step1Title: string
  step1Desc: string
  step2Num: string
  step2Title: string
  step2Desc: string
  step3Num: string
  step3Title: string
  step3Desc: string
  ctaBannerTitle: string
  ctaBannerDesc: string
  ctaBannerButton: string
  footerText: string
  socialProofBadge?: string
  socialProofTitle?: string
  socialProofSubtitle?: string
  socialProofTransparency?: string
  testimonial1Name?: string
  testimonial1Role?: string
  testimonial1Org?: string
  testimonial1Quote?: string
  testimonial1Badge?: string
  testimonial2Name?: string
  testimonial2Role?: string
  testimonial2Org?: string
  testimonial2Quote?: string
  testimonial2Badge?: string
  testimonial3Name?: string
  testimonial3Role?: string
  testimonial3Org?: string
  testimonial3Quote?: string
  testimonial3Badge?: string
  complianceBadge?: string
  complianceTitle?: string
  complianceSubtitle?: string
  complianceHipaaTitle?: string
  complianceHipaaDesc?: string
  complianceHipaaBadge?: string
  complianceFdaTitle?: string
  complianceFdaDesc?: string
  complianceFdaBadge?: string
  complianceOpenFdaTitle?: string
  complianceOpenFdaDesc?: string
  complianceOpenFdaBadge?: string
  complianceAwsTitle?: string
  complianceAwsDesc?: string
  complianceAwsBadge?: string
  complianceDisclaimer?: string
  accessPortal?: string
  previewPatientSub?: string
  previewAlertBadge?: string
  previewOverdueStatus?: string
  traditionalHeading?: string
  remoteCareHeading?: string
  pillar1Badge?: string
  pillar2Badge?: string
  pillar3Badge?: string
  complianceNoticeTitle?: string
  brandName?: string
  loginButton?: string
  awsTrack?: string
  interactivePreview?: string
  liveTelemetryTitle?: string
  liveTelemetrySubtitle?: string
  comparisonTitle?: string
  comparisonSubtitle?: string
  pillarsTitle?: string
  pillarsSubtitle?: string
  pillar1Title?: string
  pillar1Text?: string
  pillar2Title?: string
  pillar2Text?: string
  pillar3Title?: string
  pillar3Text?: string
}

export interface LoginTranslations {
  title: string
  subtitle: string
  emailPlaceholder: string
  passwordPlaceholder: string
  errorInvalid: string
  button: string
  loggingIn: string
  securityNotice?: string
  quickDemoButton?: string
  demoHelper?: string
  backToHome: string
  orSignInWithPassword?: string
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
  colActions?: string
  edit?: string
  deactivate?: string
  reactivate?: string
  inactiveBadge?: string
  activeBadge?: string
  savedBanner?: string
  deactivatedBanner?: string
  reactivatedBanner?: string
  caseDeletedBanner?: string
}

export interface EditPatientTranslations {
  title?: string
  subtitle?: string
  email?: string
  fullName?: string
  dateOfBirth?: string
  phone?: string
  phonePlaceholder?: string
  surgeryType?: string
  surgeryDate?: string
  emergencyContact?: string
  save?: string
  cancel?: string
  dangerZoneTitle?: string
  inactiveNotice?: string
  deactivateNotice?: string
  deactivate?: string
  reactivate?: string
  confirmTitle?: string
  confirmText?: string
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
  notFound?: string
  backToCaseDetail?: string
  surgeryDate?: string
  adherenceRate?: string
  latestFeeling?: string
  totalCheckins?: string
  editCase?: string
  deleteCase?: string
  confirmDeleteTitle?: string
  confirmDeleteText?: string
}

export interface Translations {
  landing: LandingTranslations
  login: LoginTranslations
  auth: AuthTranslations
  createCase: CreateCaseTranslations
  createPatient: CreatePatientTranslations
  editPatient?: EditPatientTranslations
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
