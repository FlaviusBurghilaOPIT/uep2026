import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/l10n/locale_notifier.dart';
import '../../../../core/navigation/app_routes.dart';
import '../providers/notification_prefs_notifier.dart';
import '../providers/profile_case_provider.dart';

/// Profile (WI 06 / spec Req 20–25): server truth or honest absence — no
/// hardcoded fallbacks, no dead controls. Personal info comes from
/// `GET /auth/me` and name/phone/DOB are editable via `PATCH /auth/me`
/// (email stays read-only: it is the credential). The Treatment Plan shows
/// only what the case endpoint exposes; Condition (no model field) and
/// Clinician (no patient-accessible endpoint) are omitted entirely — the
/// same honest-absence idiom as the Recovery screen, which never renders a
/// clinician name either.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  /// Honest absence for a missing scalar value in a labelled row.
  static const notProvided = 'Not provided';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);
    final caseInfo = ref.watch(profileCaseProvider);
    final notifPrefs = ref.watch(notificationPrefsProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              _buildHeader(l10n, context),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingH,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppSpacing.xl),
                    _buildProfileHeader(auth.fullName, auth.email),
                    SizedBox(height: AppSpacing.xl),
                    _buildSection(l10n.languageSectionTitle.toUpperCase(), [
                      _languageRow(
                        label: l10n.languageEnglish,
                        localeCode: 'en',
                        currentLocale: currentLocale,
                        onTap: () => ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('en')),
                      ),
                      _languageRow(
                        label: l10n.languageItalian,
                        localeCode: 'it',
                        currentLocale: currentLocale,
                        onTap: () => ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('it')),
                      ),
                      _languageRow(
                        label: l10n.languageSpanish,
                        localeCode: 'es',
                        currentLocale: currentLocale,
                        onTap: () => ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('es')),
                      ),
                      _languageRow(
                        label: l10n.languageFrench,
                        localeCode: 'fr',
                        currentLocale: currentLocale,
                        onTap: () => ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('fr')),
                      ),
                      _languageRow(
                        label: l10n.languageGerman,
                        localeCode: 'de',
                        currentLocale: currentLocale,
                        onTap: () => ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('de')),
                      ),
                    ]),
                    SizedBox(height: AppSpacing.xl),
                    _buildSection('PERSONAL INFORMATION', [
                      _infoRow(
                        'Full name',
                        auth.fullName,
                        onEdit: () => _editField(
                          context,
                          ref,
                          label: 'Full name',
                          initial: auth.fullName,
                          onSave: (v) => ref
                              .read(authProvider.notifier)
                              .updateProfile(fullName: v),
                        ),
                      ),
                      // Email is the login credential — read-only here.
                      _infoRow('Email', auth.email),
                      _infoRow(
                        'Phone',
                        auth.phone,
                        onEdit: () => _editField(
                          context,
                          ref,
                          label: 'Phone',
                          initial: auth.phone,
                          keyboardType: TextInputType.phone,
                          onSave: (v) => ref
                              .read(authProvider.notifier)
                              .updateProfile(phone: v),
                        ),
                      ),
                      _infoRow(
                        'Date of birth',
                        _formatDate(auth.dateOfBirth),
                        onEdit: () => _editField(
                          context,
                          ref,
                          label: 'Date of birth',
                          initial: auth.dateOfBirth,
                          hint: 'YYYY-MM-DD',
                          keyboardType: TextInputType.datetime,
                          onSave: (v) => ref
                              .read(authProvider.notifier)
                              .updateProfile(dateOfBirth: v),
                        ),
                      ),
                    ]),
                    SizedBox(height: AppSpacing.xl),
                    _buildSection(
                      'TREATMENT PLAN',
                      _treatmentPlanRows(caseInfo),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    _buildSection('NOTIFICATIONS', [
                      _toggleRow(
                        'Medication reminders',
                        notifPrefs.medReminders,
                        (v) => ref
                            .read(notificationPrefsProvider.notifier)
                            .setMedReminders(v),
                      ),
                      _toggleRow(
                        'Daily check-in',
                        notifPrefs.dailyCheckin,
                        (v) => ref
                            .read(notificationPrefsProvider.notifier)
                            .setDailyCheckin(v),
                      ),
                    ]),
                    SizedBox(height: AppSpacing.xl),
                    _buildSection('SECURITY', [
                      _arrowRow(
                        'Change password',
                        Icons.lock_outline,
                        onTap: () => _changePassword(context, ref),
                      ),
                    ]),
                    SizedBox(height: AppSpacing.xl),
                    _buildSignOutButton(context, ref, l10n),
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 'MMM d, yyyy' when the raw value parses, otherwise the raw server
  /// string — never a fabricated date.
  static String? _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('MMM d, yyyy').format(parsed);
  }

  /// Treatment Plan rows from server truth. Rows render only when the case
  /// exposes the value; with no case (or no usable fields) the section
  /// shows an explicit honest-absence message.
  List<Widget> _treatmentPlanRows(AsyncValue<ProfileCaseInfo?> caseInfo) {
    final info = caseInfo.value;
    if (caseInfo.isLoading && info == null) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                key: Key('profile_treatment_loading'),
                strokeWidth: 2,
              ),
            ),
          ),
        ),
      ];
    }
    final surgeryType = info?.surgeryType;
    final surgeryDate = info?.surgeryDate;
    final rows = <Widget>[
      if (surgeryType != null && surgeryType.isNotEmpty)
        _infoRow('Procedure', surgeryType),
      if (surgeryDate != null)
        _infoRow('Surgery date', DateFormat('MMM d, yyyy').format(surgeryDate)),
    ];
    if (rows.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Text(
            'Your care team has not added treatment details yet.',
            key: const Key('profile_treatment_empty'),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.greyText,
            ),
          ),
        ),
      ];
    }
    return rows;
  }

  Future<void> _editField(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String? initial,
    required Future<bool> Function(String value) onSave,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: initial ?? '');
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        var saving = false;
        String? error;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final value = controller.text.trim();
              if (value.isEmpty) {
                setDialogState(() => error = '$label cannot be empty');
                return;
              }
              setDialogState(() {
                saving = true;
                error = null;
              });
              final ok = await onSave(value);
              if (!context.mounted) return;
              if (ok) {
                Navigator.of(dialogContext).pop(true);
              } else {
                setDialogState(() {
                  saving = false;
                  error = 'Could not save. Please try again.';
                });
              }
            }

            return AlertDialog(
              title: Text('Edit $label'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: Key('edit_field_${label.toLowerCase().replaceAll(' ', '_')}'),
                    controller: controller,
                    autofocus: true,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(hintText: hint),
                    onSubmitted: (_) => submit(),
                  ),
                  if (error != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      error!,
                      key: const Key('edit_field_error'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.errorRed,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving ? null : submit,
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$label updated')));
    }
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final hasPassword = ref.read(authProvider).hasPassword;
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        var saving = false;
        String? error;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final current = currentController.text;
              final next = newController.text;
              final confirm = confirmController.text;
              // The current password is required only when one already
              // exists (code-only patients set their first password).
              if (hasPassword && current.isEmpty) {
                setDialogState(
                  () => error = 'Enter your current password',
                );
                return;
              }
              if (next.length < 8) {
                setDialogState(
                  () => error = 'New password must be at least 8 characters',
                );
                return;
              }
              if (next != confirm) {
                setDialogState(() => error = 'Passwords do not match');
                return;
              }
              setDialogState(() {
                saving = true;
                error = null;
              });
              final failure = await ref
                  .read(authProvider.notifier)
                  .changePassword(
                    newPassword: next,
                    currentPassword: hasPassword ? current : null,
                  );
              if (!context.mounted) return;
              if (failure == null) {
                Navigator.of(dialogContext).pop(true);
              } else {
                setDialogState(() {
                  saving = false;
                  error = failure;
                });
              }
            }

            return AlertDialog(
              title: const Text('Change password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasPassword)
                    TextField(
                      key: const Key('current_password_field'),
                      controller: currentController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current password',
                      ),
                    ),
                  TextField(
                    key: const Key('new_password_field'),
                    controller: newController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                    ),
                  ),
                  TextField(
                    key: const Key('confirm_password_field'),
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                  if (error != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      error!,
                      key: const Key('change_password_error'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.errorRed,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const Key('change_password_submit'),
                  onPressed: saving ? null : submit,
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    if (changed == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated')));
    }
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.lg,
        AppSpacing.screenPaddingH,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(AppStrings.remotecare, style: AppTextStyles.heading3),
          ),
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryGreen, width: 1.5),
            ),
            child: Icon(
              Icons.person_outline,
              color: AppColors.primaryGreen,
              size: AppSpacing.iconMd,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.md,
        AppSpacing.screenPaddingH,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: Container(
                width: 36.w,
                height: 36.w,
                decoration: const BoxDecoration(
                  color: AppColors.inputFill,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: AppColors.black,
                  size: AppSpacing.iconMd,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.hSm),
          Text(l10n.profileTitle, style: AppTextStyles.heading3),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String? name, String? email) {
    final hasName = name != null && name.trim().isNotEmpty;
    final initials = hasName
        ? name
              .trim()
              .split(RegExp(r'\s+'))
              .map((w) => w[0])
              .take(2)
              .join()
              .toUpperCase()
        : null;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: initials != null
                  ? Text(
                      initials,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    )
                  : Icon(
                      Icons.person_outline,
                      color: AppColors.white,
                      size: AppSpacing.iconLg,
                    ),
            ),
          ),
          SizedBox(width: AppSpacing.hMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? notProvided,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  email ?? notProvided,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.label),
        SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.greyDivider, width: 0.5),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    indent: 16.w,
                    endIndent: 16.w,
                    color: AppColors.greyDivider,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _languageRow({
    required String label,
    required String localeCode,
    required Locale currentLocale,
    required VoidCallback onTap,
  }) {
    final isSelected = currentLocale.languageCode == localeCode;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
              if (isSelected)
                Icon(
                  Icons.check,
                  color: AppColors.deepTeal,
                  size: AppSpacing.iconMd,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Labelled value row. [value] null renders [notProvided] (honest
  /// absence); [onEdit] non-null adds an edit affordance.
  Widget _infoRow(String label, String? value, {VoidCallback? onEdit}) {
    final hasValue = value != null && value.isNotEmpty;
    return InkWell(
      onTap: onEdit,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  hasValue ? value : notProvided,
                  style: hasValue
                      ? AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w500,
                        )
                      : AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.greyText,
                        ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onEdit != null) ...[
                SizedBox(width: AppSpacing.hSm),
                Icon(
                  Icons.edit_outlined,
                  color: AppColors.greyText,
                  size: AppSpacing.iconMd,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _arrowRow(String label, IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Icon(icon, color: AppColors.greyText, size: AppSpacing.iconLg),
              SizedBox(width: AppSpacing.hMd),
              Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
              Icon(
                Icons.chevron_right,
                color: AppColors.greyLight,
                size: AppSpacing.iconMd,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: OutlinedButton(
        onPressed: () async {
          await ref.read(authProvider.notifier).signOut();
          if (context.mounted) {
            AppRoutes.navigateAndClearStack(context, AppRoutes.boot);
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.errorRed,
          side: const BorderSide(color: AppColors.errorRed, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout, size: AppSpacing.iconMd),
            SizedBox(width: AppSpacing.hSm),
            Flexible(
              child: Text(
                l10n.signOutButton,
                style: AppTextStyles.buttonTextOutlined.copyWith(
                  color: AppColors.errorRed,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
