import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../oss_licenses.dart';

/// Displays Open Source Software licenses for compliance with attribution requirements.
class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.licenses),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: allDependencies.length,
        itemBuilder: (context, index) {
          final pkg = allDependencies[index];
          return ExpansionTile(
            title: Text(
              '${pkg.name}${pkg.version != null ? ' ${pkg.version}' : ''}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: pkg.description.isNotEmpty
                ? Text(
                    pkg.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            children: [
              if (pkg.license != null && pkg.license!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    pkg.license!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
