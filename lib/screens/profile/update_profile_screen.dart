import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _country = TextEditingController(text: 'Nepal');
  final _zip = TextEditingController();
  final _faculty = TextEditingController();
  final _title = TextEditingController();
  final _bio = TextEditingController();
  final _skill = TextEditingController();
  final List<String> _skills = [];
  String _competency = 'Beginner';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      final nameParts = user.name.trim().split(RegExp(r'\s+'));
      _firstName.text = nameParts.isEmpty ? '' : nameParts.first;
      _lastName.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      _email.text = user.email;
      _faculty.text = user.faculty;
      _title.text = user.title;
      _bio.text = user.bio;
      _skills.addAll(user.skillsOrInterests);
    }
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _phone, _address, _city, _state, _country,
      _zip, _faculty, _title, _bio, _skill]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateProfile(
            name: '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim(),
            bio: _bio.text.trim(),
            title: _title.text.trim(),
            faculty: _faculty.text.trim(),
            skillsOrInterests: _skills,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addSkill() {
    final value = _skill.text.trim();
    if (value.isNotEmpty && !_skills.contains(value)) {
      setState(() { _skills.add(value); _skill.clear(); });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Update Profile')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _section('Personal information', [
                Row(children: [
                  Expanded(child: _field(_firstName, 'First name', required: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_lastName, 'Last name')),
                ]),
                _field(_email, 'Email', keyboard: TextInputType.emailAddress),
                _field(_phone, 'Phone number', keyboard: TextInputType.phone),
              ]),
              _section('Address', [
                _field(_address, 'Address'),
                _field(_city, 'City'),
                _field(_state, 'State / Province'),
                _field(_country, 'Country'),
                _field(_zip, 'Zip code', keyboard: TextInputType.number),
              ]),
              _section('Mentorship and academics', [
                _field(_faculty, 'Faculty / Department'),
                _field(_title, 'Academic title'),
                DropdownButtonFormField<String>(
                  initialValue: _competency,
                  decoration: const InputDecoration(labelText: 'Competency level'),
                  items: ['Beginner', 'Intermediate', 'Advanced', 'Expert']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _competency = v ?? _competency),
                ),
                _field(_bio, 'Bio', maxLines: 4),
                Row(children: [
                  Expanded(child: _field(_skill, 'Add skill', onSubmitted: (_) => _addSkill())),
                  const SizedBox(width: 8),
                  IconButton(onPressed: _addSkill, icon: const Icon(Icons.add_circle)),
                ]),
                Wrap(
                  spacing: 8,
                  children: _skills.map((s) => Chip(
                    label: Text(s),
                    onDeleted: () => setState(() => _skills.remove(s)),
                  )).toList(),
                ),
              ]),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const CircularProgressIndicator() : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      );

  Widget _section(String title, List<Widget> children) => Card(
        margin: const EdgeInsets.only(bottom: 18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            ...children.expand((w) => [w, const SizedBox(height: 12)]).toList()..removeLast(),
          ]),
        ),
      );

  Widget _field(TextEditingController controller, String label,
      {bool required = false, TextInputType? keyboard, int maxLines = 1,
      void Function(String)? onSubmitted}) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(labelText: label),
        validator: required ? (v) => v == null || v.trim().isEmpty ? 'Required' : null : null,
      );
}
