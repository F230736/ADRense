part of '../../main.dart';

class _RegistrationMedicine {
  String name = '';
  String dose = '';
  String? condition;
}

extension _RegistrationMedicines on _ADRenseAppState {
  bool saveRegistrationMedicines() {
    final names = <String>[];
    final doses = <String, String>{};
    final links = <String, String?>{};
    final conditions = registrationLists['Medical Conditions']!;
    String? error;
    if (!registrationNone.contains('Current Medications')) {
      for (final entry in registrationMedicines) {
        final name = entry.name.trim();
        final dose = entry.dose.trim();
        if (name.isEmpty ||
            dose.isEmpty ||
            (conditions.isNotEmpty && !conditions.contains(entry.condition))) {
          error = 'Enter a name, dosage, and condition for each medicine.';
          break;
        }
        if (names
            .any((existing) => existing.toLowerCase() == name.toLowerCase())) {
          error = 'Enter each medicine only once.';
          break;
        }
        names.add(name);
        doses[name] = dose;
        links[name] = entry.condition;
      }
    }
    updateView(() {
      if (error != null) {
        formErrors['Current Medications'] = error;
        return;
      }
      formErrors.remove('Current Medications');
      registrationLists['Current Medications'] = names;
      registrationDoses
        ..clear()
        ..addAll(doses);
      registrationMedicationConditions
        ..clear()
        ..addAll(links);
    });
    return error == null;
  }

  Widget registrationMedicineFields() {
    final none = registrationNone.contains('Current Medications');
    final conditions = registrationLists['Medical Conditions']!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!none)
        for (final (index, entry) in registrationMedicines.indexed)
          Padding(
            key: ObjectKey(entry),
            padding: const EdgeInsets.only(bottom: 12),
            child: card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (registrationMedicines.length > 1)
                Row(children: [
                  Expanded(
                      child: Text('Medicine ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w700))),
                  IconButton(
                    tooltip: 'Remove medicine',
                    onPressed: () =>
                        updateView(() => registrationMedicines.remove(entry)),
                    icon: Icon(Icons.close, color: P.muted),
                  ),
                ]),
              TextFormField(
                initialValue: entry.name,
                maxLength: 120,
                onChanged: (value) => entry.name = value,
                decoration: const InputDecoration(
                    labelText: 'Medicine name',
                    hintText: 'e.g. Metformin',
                    counterText: ''),
              ),
              gap(10),
              TextFormField(
                initialValue: entry.dose,
                maxLength: 120,
                onChanged: (value) => entry.dose = value,
                decoration: const InputDecoration(
                    labelText: 'Dosage',
                    hintText: 'e.g. 500 mg twice daily',
                    counterText: ''),
              ),
              gap(10),
              MenuAnchor(
                style: MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(P.surface2),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: P.border))),
                  padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
                  maximumSize: const WidgetStatePropertyAll(Size(300, 280)),
                ),
                menuChildren: [
                  for (final condition in conditions)
                    MenuItemButton(
                      leadingIcon: Icon(
                          entry.condition == condition
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 18,
                          color: P.teal),
                      onPressed: () =>
                          updateView(() => entry.condition = condition),
                      child: Text(condition, overflow: TextOverflow.ellipsis),
                    ),
                ],
                builder: (context, controller, child) => InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: conditions.isEmpty
                      ? null
                      : () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                  child: InputDecorator(
                    decoration:
                        const InputDecoration(labelText: 'Condition treated'),
                    child: Row(children: [
                      Expanded(
                          child: Text(conditions.isEmpty
                              ? 'None'
                              : entry.condition ?? 'Select a condition')),
                      Icon(
                          conditions.isEmpty
                              ? Icons.remove
                              : Icons.expand_more_rounded,
                          color: P.teal),
                    ]),
                  ),
                ),
              ),
            ])),
          ),
      Wrap(spacing: 10, runSpacing: 8, children: [
        FilterChip(
          label: const Text('None'),
          selected: none,
          onSelected: (selected) => updateView(() {
            if (selected) {
              registrationNone.add('Current Medications');
            } else {
              registrationNone.remove('Current Medications');
            }
            formErrors.remove('Current Medications');
          }),
        ),
        if (!none)
          OutlinedButton.icon(
            onPressed: () => updateView(
                () => registrationMedicines.add(_RegistrationMedicine())),
            icon: const Icon(Icons.add),
            label: const Text('Add another medicine'),
          ),
      ]),
      inlineSelectionError('Current Medications'),
    ]);
  }
}
