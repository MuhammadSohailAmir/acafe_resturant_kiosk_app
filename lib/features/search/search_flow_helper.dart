import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:go_router/go_router.dart';

/// Shared helpers for kiosk search navigation and query parsing.
class SearchFlowHelper {
  SearchFlowHelper._();

  /// Pops the nearest route (modal sheet first, then page). Falls back to menu
  /// when there is nothing left to pop — avoids silent no-ops on deep links.
  static void navigateBack(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }

    RouterHelper.getKioskMenuRoute();
  }

  /// Decode `?text=` from the search-result route (JSON-encoded string).
  static String decodeSearchQuery(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is String) return decoded;
    } catch (_) {
      // Fall through — legacy/plain query strings.
    }
    return Uri.decodeComponent(raw);
  }

  /// Normalise route slug back to a human-readable query.
  static String queryFromRouteSlug(String? slug) =>
      (slug ?? '').replaceAll('-', ' ').trim();

  static bool hasActiveFilters({
    required int? selectedSortByIndex,
    required int? selectedPriceIndex,
    required int? selectedRatingIndex,
    required bool halalTagStatus,
    required List<int> selectedCategoryIds,
  }) {
    return selectedSortByIndex != null ||
        selectedPriceIndex != null ||
        selectedRatingIndex != null ||
        halalTagStatus ||
        selectedCategoryIds.isNotEmpty;
  }
}
