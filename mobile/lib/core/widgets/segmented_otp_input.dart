import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

/// A 6-cell segmented OTP input widget with:
/// - Auto-paste detection from clipboard on init
/// - Pasting a 6-digit code into any cell populates all cells
/// - Typing a digit auto-advances to the next cell
/// - Backspace on an empty cell auto-retreats to the previous cell
/// - Entering the 6th digit auto-submits via [onCompleted]
/// - Monospaced [FontFeature.tabularFigures] numeric styling
class SegmentedOtpInput extends StatefulWidget {
  final int length;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final FormFieldValidator<String>? validator;
  final bool autoFocus;
  final bool readOnly;
  final bool autoCheckClipboard;

  const SegmentedOtpInput({
    super.key,
    this.length = 6,
    this.controller,
    this.onChanged,
    this.onCompleted,
    this.validator,
    this.autoFocus = false,
    this.readOnly = false,
    this.autoCheckClipboard = true,
  });

  @override
  State<SegmentedOtpInput> createState() => _SegmentedOtpInputState();
}

class _SegmentedOtpInputState extends State<SegmentedOtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  FormFieldState<String>? _fieldState;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());

    _syncFromExternalController();
    widget.controller?.addListener(_handleExternalControllerChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoCheckClipboard) {
        _checkClipboard();
      }
      if (widget.autoFocus && _focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleExternalControllerChange);
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _syncFromExternalController() {
    final text = widget.controller?.text ?? '';
    for (int i = 0; i < widget.length; i++) {
      final char = i < text.length ? text[i] : '';
      if (_controllers[i].text != char) {
        _controllers[i].text = char;
      }
    }
  }

  void _handleExternalControllerChange() {
    final current = _getCode();
    final externalText = widget.controller?.text ?? '';
    if (current != externalText) {
      _syncFromExternalController();
    }
  }

  String _getCode() {
    return _controllers.map((c) => c.text).join();
  }

  void _syncCode([FormFieldState<String>? fieldState]) {
    final code = _getCode();
    if (widget.controller != null && widget.controller!.text != code) {
      widget.controller!.text = code;
    }
    final state = fieldState ?? _fieldState;
    state?.didChange(code);
    widget.onChanged?.call(code);
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.length == widget.length && RegExp(r'^\d{' + widget.length.toString() + r'}$').hasMatch(text) && mounted) {
        for (int i = 0; i < widget.length; i++) {
          _controllers[i].text = text[i];
        }
        if (widget.length > 0) {
          _focusNodes[widget.length - 1].requestFocus();
        }
        _syncCode();
        widget.onCompleted?.call(text);
      }
    } catch (_) {}
  }

  void _onCellChanged(int index, String val, FormFieldState<String> fieldState) {
    if (val.length >= widget.length) {
      // 6-digit (or longer) paste into any cell
      final fullCode = val.substring(0, widget.length);
      for (int i = 0; i < widget.length; i++) {
        _controllers[i].text = fullCode[i];
      }
      _focusNodes[widget.length - 1].requestFocus();
      _syncCode(fieldState);
      if (RegExp(r'^\d{' + widget.length.toString() + r'}$').hasMatch(fullCode)) {
        widget.onCompleted?.call(fullCode);
      }
      return;
    }

    if (val.length > 1) {
      // If cell already had 1 char and user typed a 2nd char in this cell:
      if (val.length == 2 && _controllers[index].text.isNotEmpty) {
        final newChar = val[val.length - 1];
        _controllers[index].text = newChar;
        _syncCode(fieldState);
        if (index < widget.length - 1) {
          _focusNodes[index + 1].requestFocus();
        } else {
          final code = _getCode();
          if (code.length == widget.length && RegExp(r'^\d{' + widget.length.toString() + r'}$').hasMatch(code)) {
            widget.onCompleted?.call(code);
          }
        }
        return;
      }

      // Otherwise distribute characters across cells starting from index
      for (int k = 0; k < val.length && (index + k) < widget.length; k++) {
        _controllers[index + k].text = val[k];
      }
      final nextFocus = (index + val.length).clamp(0, widget.length - 1);
      _focusNodes[nextFocus].requestFocus();
      _syncCode(fieldState);
      final code = _getCode();
      if (code.length == widget.length && RegExp(r'^\d{' + widget.length.toString() + r'}$').hasMatch(code)) {
        widget.onCompleted?.call(code);
      }
      return;
    }

    if (val.length == 1) {
      _controllers[index].text = val;
      _syncCode(fieldState);
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        final code = _getCode();
        if (code.length == widget.length && RegExp(r'^\d{' + widget.length.toString() + r'}$').hasMatch(code)) {
          widget.onCompleted?.call(code);
        }
      }
      return;
    }

    if (val.isEmpty) {
      _controllers[index].text = '';
      _syncCode(fieldState);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator,
      initialValue: widget.controller?.text ?? '',
      builder: (FormFieldState<String> fieldState) {
        _fieldState = fieldState;
        final hasError = fieldState.hasError && fieldState.errorText != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.length, (index) {
                return SizedBox(
                  width: 48.w,
                  height: 56.h,
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.backspace) {
                        if (_controllers[index].text.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                          _controllers[index - 1].text = '';
                          _syncCode(fieldState);
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextFormField(
                      key: ValueKey('otp_cell_$index'),
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      readOnly: widget.readOnly,
                      style: AppTextStyles.otpDigitText,
                      maxLength: widget.length,
                      buildCounter: (_, {required currentLength, required isFocused, required maxLength}) => null,
                      autofillHints: index == 0 ? const [AutofillHints.oneTimeCode] : null,
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: hasError
                              ? const BorderSide(color: AppColors.errorRed, width: 1.5)
                              : BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(
                            color: AppColors.primaryGreen,
                            width: 2.0,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(
                            color: AppColors.errorRed,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (val) => _onCellChanged(index, val, fieldState),
                    ),
                  ),
                );
              }),
            ),
            if (hasError) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                fieldState.errorText!,
                style: TextStyle(
                  color: AppColors.errorRed,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
