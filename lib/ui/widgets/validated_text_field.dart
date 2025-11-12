import 'package:flutter/material.dart';
import 'package:card_scan/services/validation_service.dart';

/// Custom text field with built-in validation
class ValidatedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValidationResult Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final void Function(String)? onChanged;
  final VoidCallback? onEditingComplete;
  final bool autovalidate;
  final String? initialValue;

  const ValidatedTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
    this.onEditingComplete,
    this.autovalidate = false,
    this.initialValue,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  late TextEditingController _controller;
  ValidationResult? _validationResult;
  bool _hasBeenTouched = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);

    if (widget.autovalidate) {
      _controller.addListener(_validateOnChange);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _validateOnChange() {
    if (_hasBeenTouched || widget.autovalidate) {
      _validate(_controller.text);
    }
  }

  void _validate(String value) {
    if (widget.validator != null) {
      setState(() {
        _validationResult = widget.validator!(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _controller,
          enabled: widget.enabled,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          style: TextStyle(
            color: widget.enabled ? Colors.white : Colors.white54,
          ),
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: theme.primaryColor)
                : null,
            suffixIcon: widget.suffixIcon ?? _buildSuffixIcon(),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            labelStyle: TextStyle(
              color: Colors.white.withOpacity(0.7),
            ),
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
            ),
            counterStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          onChanged: (value) {
            if (!_hasBeenTouched) {
              setState(() => _hasBeenTouched = true);
            }
            _validateOnChange();
            widget.onChanged?.call(value);
          },
          onEditingComplete: widget.onEditingComplete,
        ),
        if (_validationResult != null && !_validationResult!.isValid)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Row(
              children: [
                Icon(
                  _validationResult!.level == ValidationLevel.warning
                      ? Icons.warning_amber
                      : Icons.error_outline,
                  size: 16,
                  color: _validationResult!.level == ValidationLevel.warning
                      ? Colors.orange
                      : Colors.red,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _validationResult!.message ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: _validationResult!.level == ValidationLevel.warning
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (_validationResult == null) return null;

    if (_validationResult!.isValid && _hasBeenTouched) {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
      );
    } else if (!_validationResult!.isValid) {
      return Icon(
        _validationResult!.level == ValidationLevel.warning
            ? Icons.warning_amber
            : Icons.error,
        color: _validationResult!.level == ValidationLevel.warning
            ? Colors.orange
            : Colors.red,
      );
    }

    return null;
  }
}

/// Email text field with built-in validation
class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final bool enabled;
  final void Function(String)? onChanged;

  const EmailTextField({
    super.key,
    this.controller,
    this.labelText,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValidatedTextField(
      controller: controller,
      labelText: labelText ?? 'Email',
      hintText: 'name@example.com',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: ValidationService.validateEmail,
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}

/// Phone text field with built-in validation
class PhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final bool enabled;
  final void Function(String)? onChanged;

  const PhoneTextField({
    super.key,
    this.controller,
    this.labelText,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValidatedTextField(
      controller: controller,
      labelText: labelText ?? 'Phone',
      hintText: '+1 (555) 123-4567',
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: ValidationService.validatePhone,
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}

/// URL text field with built-in validation
class UrlTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final bool enabled;
  final void Function(String)? onChanged;

  const UrlTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValidatedTextField(
      controller: controller,
      labelText: labelText ?? 'Website',
      hintText: hintText ?? 'www.example.com',
      prefixIcon: Icons.language_outlined,
      keyboardType: TextInputType.url,
      validator: ValidationService.validateUrl,
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}

/// Name text field with built-in validation
class NameTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final bool enabled;
  final void Function(String)? onChanged;

  const NameTextField({
    super.key,
    this.controller,
    this.labelText,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValidatedTextField(
      controller: controller,
      labelText: labelText ?? 'Name',
      hintText: 'John Doe',
      prefixIcon: Icons.person_outlined,
      keyboardType: TextInputType.name,
      validator: ValidationService.validateName,
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}
