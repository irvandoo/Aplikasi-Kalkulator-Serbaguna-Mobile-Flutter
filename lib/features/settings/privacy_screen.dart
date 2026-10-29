import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  late Future<String> _text = _load();

  Future<String> _load() =>
      rootBundle.loadString('assets/legal/kebijakan_privasi.txt');

  @override
  Widget build(BuildContext context) {
    return ToolPage(
      title: 'Kebijakan Privasi',
      child: FutureBuilder<String>(
        future: _text,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Kebijakan privasi tidak dapat dimuat.'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => setState(() => _text = _load()),
                  child: const Text('Coba lagi'),
                ),
              ]),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(snap.data!,
                style: Theme.of(context).textTheme.bodyMedium),
          );
        },
      ),
    );
  }
}
