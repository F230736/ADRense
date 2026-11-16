part of '../../main.dart';

extension _AccountViews on _ADRenseAppState {
  Widget changePasswordLink() => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('Change Password', style: TextStyle(color: P.teal)),
        trailing: Icon(Icons.chevron_right, color: P.teal),
        onTap: () => go('changePassword'),
      );

  Widget analystProfile() {
    const labels = {
      'professional_email': 'Professional Email',
      'phone': 'Phone Number',
      'country': 'Country',
      'professional_role': 'Professional Role',
      'profession': 'Profession',
      'qualification': 'Qualification / Degree',
      'institution': 'University / Institution',
      'graduation_year': 'Graduation Year',
      'license_number': 'License / Registration Number',
      'issuing_authority': 'Issuing Authority',
      'license_expiry': 'Expiry Date',
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      analystTopBar(),
      if (profileSaveError != null)
        Text(profileSaveError!, style: TextStyle(color: P.danger)),
      profileCard('Basic Information', [('Full Name', ''), ('Email', '')]),
      gap(12),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Professional Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        gap(12),
        for (final (label, value) in [
          for (final field in labels.entries)
            (field.value, analystProfileData[field.key]?.toString()),
        ])
          if (value != null && value.isNotEmpty) ...[
            Text(label, style: TextStyle(color: P.muted, fontSize: 12)),
            gap(4),
            SelectableText(value,
                style: const TextStyle(fontWeight: FontWeight.w400)),
            gap(10),
            Divider(color: P.border, height: 1),
            gap(10),
          ],
      ])),
    ]);
  }
}

class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({
    super.key,
    required this.api,
    required this.validPassword,
    required this.onBack,
    required this.onChanged,
  });

  final ApiService api;
  final bool Function(String) validPassword;
  final VoidCallback onBack;
  final Future<void> Function() onChanged;

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final form = GlobalKey<FormState>();
  final current = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool saving = false;
  final visible = <TextEditingController>{};
  String? error;

  @override
  void dispose() {
    current.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.api
          .changePassword(current.text, password.text, confirmation.text);
      if (mounted) await widget.onChanged();
    } on AuthApiException catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget field(String label, TextEditingController controller,
          FormFieldValidator<String> validate) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controller,
          enabled: !saving,
          obscureText: !visible.contains(controller),
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: label,
            errorMaxLines: 3,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip:
                  visible.contains(controller) ? 'Hide $label' : 'Show $label',
              onPressed: () => setState(() {
                if (!visible.remove(controller)) visible.add(controller);
              }),
              icon: Icon(visible.contains(controller)
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
            ),
          ),
          validator: validate,
        ),
      );

  @override
  Widget build(BuildContext context) => Form(
        key: form,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            IconButton(
              tooltip: 'Back to profile',
              onPressed: saving ? null : widget.onBack,
              icon: const Icon(Icons.chevron_left),
            ),
            const Expanded(
                child: Text('Change Password',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 20))),
          ]),
          const SizedBox(height: 18),
          GradientCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                field(
                    'Current password',
                    current,
                    (value) => value == null || value.isEmpty
                        ? 'Enter your current password.'
                        : null),
                field('New password', password, (value) {
                  if (!widget.validPassword(value ?? '')) {
                    return 'Use 8 or more characters, uppercase, lowercase and a special character. Spaces are not allowed.';
                  }
                  return value == current.text
                      ? 'Choose a different password.'
                      : null;
                }),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: password,
                  builder: (context, value, child) {
                    final valid = widget.validPassword(value.text);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(children: [
                        Icon(
                            valid
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            size: 18,
                            color: valid ? P.success : P.muted),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                valid
                                    ? 'Password meets the requirements'
                                    : '8+ characters, uppercase, lowercase and a special character. No spaces.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: valid ? P.success : P.muted))),
                      ]),
                    );
                  },
                ),
                field(
                    'Confirm new password',
                    confirmation,
                    (value) => value != password.text
                        ? 'Passwords do not match.'
                        : null),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(error!, style: TextStyle(color: P.danger)),
                  ),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
                  onPressed: saving ? null : submit,
                  child:
                      Text(saving ? 'Changing password…' : 'Change Password'),
                ),
              ])),
        ]),
      );
}
