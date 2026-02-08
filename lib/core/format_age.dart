import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Returns localized age string from [dateOfBirth], or "—" if null/future.
String formatAge(BuildContext context, DateTime? dateOfBirth) {
  final l10n = AppLocalizations.of(context)!;
  final dob = dateOfBirth;
  if (dob == null) return l10n.ageUnknown;
  final now = DateTime.now();
  if (now.isBefore(dob)) return l10n.ageUnknown;
  int years = now.year - dob.year;
  int months = now.month - dob.month;
  int days = now.day - dob.day;
  if (days < 0) {
    months--;
    final daysInPrevMonth = DateTime(now.year, now.month, 0).day;
    days += daysInPrevMonth - dob.day + now.day;
  }
  if (months < 0) {
    years--;
    months += 12;
  }
  if (years > 0) return l10n.ageYearsMonthsDays(years, months, days);
  if (months > 0) return l10n.ageMonthsDays(months, days);
  return l10n.ageDays(days);
}
