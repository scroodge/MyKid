import 'package:flutter/material.dart';

import '../../data/child.dart';
import '../../data/children_repository.dart';

class ChildEditScreen extends StatefulWidget {
  const ChildEditScreen({super.key, this.child});

  final Child? child;

  @override
  State<ChildEditScreen> createState() => _ChildEditScreenState();
}

class _ChildEditScreenState extends State<ChildEditScreen> {
  final _repo = ChildrenRepository();
  final _nameController = TextEditingController();
  DateTime? _dateOfBirth;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.child != null) {
      _nameController.text = widget.child!.name;
      _dateOfBirth = widget.child!.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    if (widget.child == null) {
      final created = await _repo.create(name: name, dateOfBirth: _dateOfBirth);
      if (mounted && created != null) Navigator.of(context).pop(created);
    } else {
      final updated = await _repo.update(
        widget.child!.id,
        name: name,
        dateOfBirth: _dateOfBirth,
      );
      if (mounted && updated != null) Navigator.of(context).pop(updated);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.child == null ? 'Add child' : 'Edit child'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(_dateOfBirth == null ? 'Date of birth (optional)' : 'Born ${_dateOfBirth!.day}.${_dateOfBirth!.month}.${_dateOfBirth!.year}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dateOfBirth ?? DateTime.now(),
                firstDate: DateTime(2010),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _dateOfBirth = picked);
            },
          ),
        ],
      ),
    );
  }
}
