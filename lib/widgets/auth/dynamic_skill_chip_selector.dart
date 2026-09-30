import 'package:flutter/material.dart';

class DynamicSkillChipSelector extends StatefulWidget {
  final List<String> options;
  final List<String> selectedSkills;
  final ValueChanged<List<String>> onChanged;
  final String label;

  const DynamicSkillChipSelector({
    super.key,
    required this.options,
    required this.selectedSkills,
    required this.onChanged,
    this.label = 'Skills',
  });

  @override
  State<DynamicSkillChipSelector> createState() =>
      _DynamicSkillChipSelectorState();
}

class _DynamicSkillChipSelectorState extends State<DynamicSkillChipSelector> {
  late final TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _addCustomSkill(String value) {
    final skill = value.trim();
    if (skill.isEmpty || widget.selectedSkills.contains(skill)) return;
    widget.onChanged([...widget.selectedSkills, skill]);
    _customController.clear();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.label,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.options
                .map((skill) => FilterChip(
                      label: Text(skill),
                      selected: widget.selectedSkills.contains(skill),
                      onSelected: (selected) {
                        final skills = [...widget.selectedSkills];
                        if (selected) {
                          skills.add(skill);
                        } else {
                          skills.remove(skill);
                        }
                        widget.onChanged(skills);
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _customController,
            textInputAction: TextInputAction.done,
            onSubmitted: _addCustomSkill,
            decoration: InputDecoration(
              labelText: 'Add Custom Skill',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: IconButton(
                onPressed: () => _addCustomSkill(_customController.text),
                icon: const Icon(Icons.add),
                tooltip: 'Add skill',
              ),
            ),
          ),
        ],
      );
}
