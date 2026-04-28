import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/cartaz_form_data.dart';
import '../../widgets/cartazes/cartaz_text_adjustments.dart';

class SavedCartaz {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CartazFormData data;
  final CartazTextAdjustments textAdjustments;

  const SavedCartaz({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.data,
    required this.textAdjustments,
  });

  String get title {
    final linha1 = data.tituloLinha1.trim();
    return linha1.isEmpty ? data.tipo.label : linha1.toUpperCase();
  }

  String get subtitle {
    final parts = <String>[
      data.tipo.label,
      data.tamanho.label,
      if (data.preco.trim().isNotEmpty) data.preco.trim(),
    ];
    return parts.join(' - ');
  }

  SavedCartaz copyWith({
    DateTime? updatedAt,
    CartazFormData? data,
    CartazTextAdjustments? textAdjustments,
  }) {
    return SavedCartaz(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      data: data ?? this.data,
      textAdjustments: textAdjustments ?? this.textAdjustments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'data': data.toJson(),
      'textAdjustments': cartazTextAdjustmentsToJson(textAdjustments),
    };
  }

  factory SavedCartaz.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return SavedCartaz(
      id: json['id'] as String? ?? CartazHistoryStore.newId(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
      data: CartazFormData.fromJson(
        Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
      ),
      textAdjustments: cartazTextAdjustmentsFromJson(json['textAdjustments']),
    );
  }
}

class CartazHistoryStore {
  static const _key = 'cartazes_feitos_v1';
  static const _maxItems = 80;

  static String newId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  static Future<List<SavedCartaz>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final items = decoded
          .whereType<Map>()
          .map((item) => SavedCartaz.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    } catch (_) {
      return [];
    }
  }

  static Future<SavedCartaz> upsert({
    required String id,
    required CartazFormData data,
    required CartazTextAdjustments textAdjustments,
  }) async {
    final items = await loadAll();
    final now = DateTime.now();
    final index = items.indexWhere((item) => item.id == id);

    final entry = index >= 0
        ? items[index].copyWith(
            updatedAt: now,
            data: data,
            textAdjustments: Map<CartazTextElement, CartazTextAdjustment>.from(
              textAdjustments,
            ),
          )
        : SavedCartaz(
            id: id,
            createdAt: now,
            updatedAt: now,
            data: data,
            textAdjustments: Map<CartazTextElement, CartazTextAdjustment>.from(
              textAdjustments,
            ),
          );

    if (index >= 0) {
      items[index] = entry;
    } else {
      items.insert(0, entry);
    }

    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final limitedItems = items.take(_maxItems).toList();
    await _saveAll(limitedItems);
    return entry;
  }

  static Future<void> delete(String id) async {
    final items = await loadAll();
    items.removeWhere((item) => item.id == id);
    await _saveAll(items);
  }

  static Future<void> _saveAll(List<SavedCartaz> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
