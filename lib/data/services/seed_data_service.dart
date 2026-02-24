import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../datasources/remote/caixa_remote_datasource.dart';
import '../models/caixa_model.dart';
import '../../domain/enums/tipo_caixa.dart';

/// Serviço para popular dados iniciais no Supabase
class SeedDataService {
  final CaixaRemoteDataSource _remote;
  final _uuid = const Uuid();

  SeedDataService(this._remote);

  /// Popula 8 caixas iniciais no Supabase (somente na primeira vez)
  Future<void> seedCaixas(String fiscalId) async {
    try {
      final existentes = await _remote.getCaixas(fiscalId);

      if (existentes.isNotEmpty) {
        debugPrint('[SeedData] Caixas já existem no Supabase, pulando seed');
        return;
      }

      debugPrint('[SeedData] Criando 8 caixas iniciais no Supabase...');

      final agora = DateTime.now();
      final caixas = <CaixaModel>[
        // Caixas Rápidos (1 e 2)
        CaixaModel(
          id: _uuid.v4(),
          fiscalId: fiscalId,
          numero: 1,
          tipo: TipoCaixa.rapido,
          ativo: true,
          emManutencao: false,
          createdAt: agora,
          updatedAt: agora,
        ),
        CaixaModel(
          id: _uuid.v4(),
          fiscalId: fiscalId,
          numero: 2,
          tipo: TipoCaixa.rapido,
          ativo: true,
          emManutencao: false,
          createdAt: agora,
          updatedAt: agora,
        ),
        // Caixas Normais (3–8)
        ...List.generate(6, (i) {
          return CaixaModel(
            id: _uuid.v4(),
            fiscalId: fiscalId,
            numero: i + 3,
            tipo: TipoCaixa.normal,
            ativo: true,
            emManutencao: false,
            createdAt: agora,
            updatedAt: agora,
          );
        }),
      ];

      for (final caixa in caixas) {
        await _remote.upsertCaixa(caixa);
      }

      debugPrint('[SeedData] ✅ 8 caixas criados no Supabase!');
    } catch (e) {
      debugPrint('[SeedData] Erro ao criar caixas: $e');
    }
  }
}
