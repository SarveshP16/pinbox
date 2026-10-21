import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/text_link_button.dart';
import '../application/vault_controller.dart';
import '../domain/bank_grouping.dart';
import '../domain/entry_type.dart';
import '../domain/entry_validation.dart';
import '../domain/new_entry_id.dart';
import '../domain/vault_entry.dart';
import 'widgets/entry_type_chips.dart';

/// Screen 4: add a new entry, or (when [entryId] is given) edit an existing one.
class AddEditPinScreen extends ConsumerStatefulWidget {
  const AddEditPinScreen({super.key, this.entryId});

  final String? entryId;

  @override
  ConsumerState<AddEditPinScreen> createState() => _AddEditPinScreenState();
}

class _AddEditPinScreenState extends ConsumerState<AddEditPinScreen> {
  late final VaultEntry? _editing = widget.entryId == null
      ? null
      : ref
            .read(vaultProvider)
            .value
            ?.where((e) => e.id == widget.entryId)
            .firstOrNull;

  late final _bank = TextEditingController(text: _editing?.bank);
  late final _last4 = TextEditingController(text: _editing?.cardLast4);
  late final _secret = TextEditingController(text: _editing?.secret);
  late final _extraPassword = TextEditingController();
  late final _accountName = TextEditingController(text: _editing?.accountName);
  late final _routing = TextEditingController(text: _editing?.routingCode);
  late final _cif = TextEditingController(text: _editing?.cifNumber);
  late final _nickname = TextEditingController(text: _editing?.nickname);
  late final _notes = TextEditingController(text: _editing?.notes);

  late EntryType _type = _editing?.type ?? EntryType.debitCard;
  bool _addPasswordToo = false;
  bool _showSecret = false;
  bool _saving = false;

  String? _bankError;
  String? _last4Error;
  String? _secretError;
  String? _extraError;
  String? _accountNameError;
  String? _routingError;

  bool get _isEdit => _editing != null;

  @override
  void dispose() {
    for (final c in [
      _bank,
      _last4,
      _secret,
      _extraPassword,
      _accountName,
      _routing,
      _cif,
      _nickname,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectType(EntryType type) {
    setState(() {
      _type = type;
      _secretError = null;
      _last4Error = null;
      _accountNameError = null;
      _routingError = null;
      _showSecret = false;
      if (type == EntryType.password || type.isBankInfo) {
        _addPasswordToo = false;
      }
      // PINs and account numbers can't hold letters, so drop a password that was
      // typed under another type.
      if ((type.isNumeric || type.isBankInfo) &&
          !RegExp(r'^\d*$').hasMatch(_secret.text)) {
        _secret.clear();
      }
    });
  }

  bool _validate() {
    final bankError = EntryValidation.bank(_bank.text);
    final last4Error = _type.isCard
        ? EntryValidation.cardLast4(_last4.text)
        : null;
    final secretError = EntryValidation.secret(_type, _secret.text);
    final extraError = _addPasswordToo
        ? EntryValidation.secret(EntryType.password, _extraPassword.text)
        : null;
    final accountNameError = _type.isBankInfo
        ? EntryValidation.accountName(_accountName.text)
        : null;
    final routingError = _type.isBankInfo
        ? EntryValidation.routingCode(_routing.text)
        : null;
    setState(() {
      _bankError = bankError;
      _last4Error = last4Error;
      _secretError = secretError;
      _extraError = extraError;
      _accountNameError = accountNameError;
      _routingError = routingError;
    });
    return [
      bankError,
      last4Error,
      secretError,
      extraError,
      accountNameError,
      routingError,
    ].every((e) => e == null);
  }

  Future<void> _save() async {
    if (_saving || !_validate()) return;
    setState(() => _saving = true);

    final vault = ref.read(vaultProvider.notifier);
    final all = ref.read(vaultProvider).value ?? const <VaultEntry>[];
    final bank = resolveBankName(
      _bank.text,
      all.where((e) => e.id != _editing?.id),
    );
    final now = DateTime.now();
    final last4 = _type.isCard ? _last4.text : '';
    // Bank Info fields only apply to Bank Info; clear them if the type was changed.
    final accountName = _type.isBankInfo ? _accountName.text.trim() : '';
    final routing = _type.isBankInfo
        ? EntryValidation.tidyRoutingCode(_routing.text)
        : '';
    final cif = _type.isBankInfo ? _cif.text.trim().toUpperCase() : '';

    try {
      final editing = _editing;
      if (editing != null) {
        await vault.updateEntry(
          editing.copyWith(
            bank: bank,
            type: _type,
            secret: _secret.text,
            cardLast4: last4,
            nickname: _nickname.text.trim(),
            notes: _notes.text.trim(),
            accountName: accountName,
            routingCode: routing,
            cifNumber: cif,
            updatedAt: now,
          ),
        );
      } else {
        await vault.addAll([
          VaultEntry(
            id: newEntryId(),
            bank: bank,
            type: _type,
            secret: _secret.text,
            cardLast4: last4,
            nickname: _nickname.text.trim(),
            notes: _notes.text.trim(),
            accountName: accountName,
            routingCode: routing,
            cifNumber: cif,
            createdAt: now,
            updatedAt: now,
          ),
          if (_addPasswordToo)
            VaultEntry(
              id: newEntryId(),
              bank: bank,
              type: EntryType.password,
              secret: _extraPassword.text,
              // One millisecond later so it files after the entry it accompanies.
              createdAt: now.add(const Duration(milliseconds: 1)),
              updatedAt: now,
            ),
        ]);
      }
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, 'Couldn’t save. Please try again.');
      return;
    }

    if (!mounted) return;
    showAppSnackBar(context, _isEdit ? 'Changes saved' : 'Saved to your vault');
    context.pop();
  }

  /// Account name, account number, BSB/IFSC and optional CIF — shown instead of the
  /// PIN/password field when the type is Bank Info.
  List<Widget> _bankInfoFields() => [
    const SizedBox(height: 20),
    AppTextField(
      label: 'Account name',
      controller: _accountName,
      errorText: _accountNameError,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      onChanged: (_) => setState(() => _accountNameError = null),
    ),
    const SizedBox(height: 22),
    AppTextField(
      label: 'Account number',
      controller: _secret,
      errorText: _secretError,
      helper: 'Encrypted and kept on this device only.',
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(EntryValidation.maxAccountLength),
      ],
      onChanged: (_) => setState(() => _secretError = null),
    ),
    const SizedBox(height: 22),
    AppTextField(
      label: 'BSB / IFSC',
      controller: _routing,
      errorText: _routingError,
      hint: 'e.g. 123-456 or SBIN0001234',
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 \-]')),
        LengthLimitingTextInputFormatter(13),
      ],
      onChanged: (_) => setState(() => _routingError = null),
    ),
    const SizedBox(height: 22),
    AppTextField(
      label: 'CIF number (optional)',
      controller: _cif,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
        LengthLimitingTextInputFormatter(20),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final numeric = _type.isNumeric;
    final secretLabel = numeric ? 'PIN' : 'Password';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: _isEdit ? 'Edit PIN' : 'Add PIN'),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Bank',
                      controller: _bank,
                      errorText: _bankError,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() => _bankError = null),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'What are you saving?',
                      style: AppText.body(13.5, weight: 600),
                    ),
                    const SizedBox(height: 9),
                    EntryTypeChips(selected: _type, onSelected: _selectType),
                    if (_type.isCard) ...[
                      const SizedBox(height: 20),
                      AppTextField(
                        label: 'Last 4 digits of the card',
                        controller: _last4,
                        errorText: _last4Error,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        onChanged: (_) => setState(() => _last4Error = null),
                      ),
                    ],
                    if (_type.isBankInfo)
                      ..._bankInfoFields()
                    else ...[
                      const SizedBox(height: 22),
                      AppTextField(
                        label: secretLabel,
                        controller: _secret,
                        errorText: _secretError,
                        pinDots: numeric,
                        helper: 'Encrypted and kept on this device only.',
                        obscureText: numeric || !_showSecret,
                        keyboardType: numeric
                            ? TextInputType.number
                            : TextInputType.visiblePassword,
                        textInputAction: TextInputAction.next,
                        inputFormatters: numeric
                            ? [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(
                                  EntryValidation.maxPinLength,
                                ),
                              ]
                            : null,
                        // PINs stay dotted, as designed; a long password gets an eye toggle.
                        suffix: numeric
                            ? null
                            : IconButton(
                                tooltip: _showSecret
                                    ? 'Hide password'
                                    : 'Show password',
                                onPressed: () =>
                                    setState(() => _showSecret = !_showSecret),
                                icon: Icon(
                                  _showSecret
                                      ? LucideIcons.eyeOff
                                      : LucideIcons.eye,
                                  size: 22,
                                  color: context.colors.muted,
                                ),
                              ),
                        onChanged: (_) => setState(() => _secretError = null),
                      ),
                    ],
                    if (_addPasswordToo) ...[
                      const SizedBox(height: 22),
                      AppTextField(
                        label: 'Password',
                        controller: _extraPassword,
                        errorText: _extraError,
                        helper:
                            'Saved as its own Password entry under this bank.',
                        obscureText: true,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() => _extraError = null),
                      ),
                    ],
                    if (!_isEdit &&
                        _type != EntryType.password &&
                        !_type.isBankInfo)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: TextLinkButton(
                          padding: const EdgeInsets.fromLTRB(4.5, 12, 8, 12),
                          icon: _addPasswordToo
                              ? LucideIcons.x
                              : LucideIcons.plus,
                          label: _addPasswordToo
                              ? 'Remove password'
                              : 'Add a password too',
                          onPressed: () => setState(() {
                            _addPasswordToo = !_addPasswordToo;
                            _extraError = null;
                            if (!_addPasswordToo) _extraPassword.clear();
                          }),
                        ),
                      ),
                    const SizedBox(height: 22),
                    AppTextField(
                      label: 'Nickname (optional)',
                      controller: _nickname,
                      hint: _type.isBankInfo
                          ? 'e.g. Salary account'
                          : 'e.g. Everyday account',
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 22),
                    AppTextField(
                      label: 'Notes (optional)',
                      controller: _notes,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: _isEdit
                      ? 'Save changes'
                      : _type.isBankInfo
                      ? 'Save details'
                      : (numeric ? 'Save PIN' : 'Save password'),
                  icon: LucideIcons.lock,
                  onPressed: _saving ? null : _save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
