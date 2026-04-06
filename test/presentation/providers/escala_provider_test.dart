import 'package:flutter_test/flutter_test.dart';

import 'package:fiscal_assistant/domain/entities/colaborador.dart';
import 'package:fiscal_assistant/domain/enums/departamento_tipo.dart';
import 'package:fiscal_assistant/presentation/providers/escala_provider.dart';

void main() {
  group('EscalaProvider.gerarEscalaPorDia', () {
    final dataAlvo = DateTime(2026, 4, 7);
    final outroDia = DateTime(2026, 4, 8);

    Colaborador colaborador({
      required String id,
      required String nome,
    }) {
      final agora = DateTime(2026, 4, 1, 8);
      return Colaborador(
        id: id,
        fiscalId: 'fiscal-teste',
        nome: nome,
        departamento: DepartamentoTipo.caixa,
        createdAt: agora,
        updatedAt: agora,
      );
    }

    test('gera turnos apenas para a data escolhida e preserva outros dias',
        () async {
      final colaboradores = [
        colaborador(id: '1', nome: 'Ana'),
        colaborador(id: '2', nome: 'Bruno'),
      ];
      final upserts = <List<Map<String, dynamic>>>[];
      DateTime? dataConsultada;

      final provider = EscalaProvider(
        fiscalIdOverride: 'fiscal-teste',
        turnosIniciais: [
          TurnoLocal(
            id: 'turno-outro-dia',
            colaboradorId: '1',
            colaboradorNome: 'Ana',
            departamento: DepartamentoTipo.caixa,
            data: outroDia,
            entrada: '09:00',
            intervalo: '13:00',
            retorno: '14:00',
            saida: '18:00',
          ),
        ],
        buscarRegistrosPontoPorDia: (ids, data) async {
          dataConsultada = data;
          return [
            {
              'colaborador_id': '1',
              'data': '2026-04-07',
              'entrada': '08:00',
              'intervalo_saida': '12:00',
              'intervalo_retorno': '13:00',
              'saida': '17:00',
              'observacao': null,
            },
          ];
        },
        upsertTurnosEscala: (rows) async {
          upserts.add(rows);
        },
      );

      final resultado = await provider.gerarEscalaPorDia(
        colaboradores: colaboradores,
        data: dataAlvo,
      );

      expect(dataConsultada, equals(dataAlvo));
      expect(resultado, equals({'criados': 1, 'semRegistro': 1}));
      expect(provider.getTurnosByData(dataAlvo), hasLength(1));
      expect(provider.getTurnosByData(outroDia), hasLength(1));
      expect(provider.getTurnosByData(dataAlvo).single.colaboradorId, '1');
      expect(provider.getTurnosByData(outroDia).single.id, 'turno-outro-dia');
      expect(upserts, hasLength(1));
      expect(upserts.single, hasLength(1));
      expect(upserts.single.single['data'], '2026-04-07');
    });

    test('substitui somente a data alvo e remove turnos antigos dela',
        () async {
      final colaboradores = [
        colaborador(id: '1', nome: 'Ana'),
        colaborador(id: '2', nome: 'Bruno'),
      ];
      final removidos = <String>[];
      final upserts = <List<Map<String, dynamic>>>[];

      final provider = EscalaProvider(
        fiscalIdOverride: 'fiscal-teste',
        turnosIniciais: [
          TurnoLocal(
            id: 'antigo-1',
            colaboradorId: '1',
            colaboradorNome: 'Ana',
            departamento: DepartamentoTipo.caixa,
            data: dataAlvo,
            entrada: '07:00',
            intervalo: '11:00',
            retorno: '12:00',
            saida: '16:00',
          ),
          TurnoLocal(
            id: 'antigo-2',
            colaboradorId: '2',
            colaboradorNome: 'Bruno',
            departamento: DepartamentoTipo.caixa,
            data: dataAlvo,
            entrada: '10:00',
            intervalo: '14:00',
            retorno: '15:00',
            saida: '19:00',
          ),
          TurnoLocal(
            id: 'mantem-outro-dia',
            colaboradorId: '1',
            colaboradorNome: 'Ana',
            departamento: DepartamentoTipo.caixa,
            data: outroDia,
            entrada: '09:00',
            intervalo: '13:00',
            retorno: '14:00',
            saida: '18:00',
          ),
        ],
        buscarRegistrosPontoPorDia: (ids, data) async {
          return [
            {
              'colaborador_id': '2',
              'data': '2026-04-07',
              'entrada': '11:00',
              'intervalo_saida': '15:00',
              'intervalo_retorno': '16:00',
              'saida': '20:00',
              'observacao': null,
            },
          ];
        },
        upsertTurnosEscala: (rows) async {
          upserts.add(rows);
        },
        removerTurnosEscala: (ids) async {
          removidos.addAll(ids);
        },
      );

      final resultado = await provider.gerarEscalaPorDia(
        colaboradores: colaboradores,
        data: dataAlvo,
        substituirExistentes: true,
      );

      expect(resultado, equals({'criados': 1, 'semRegistro': 1}));
      expect(removidos, containsAll(['antigo-1', 'antigo-2']));
      expect(provider.getTurnosByData(dataAlvo), hasLength(1));
      expect(provider.getTurnosByData(dataAlvo).single.colaboradorId, '2');
      expect(provider.getTurnosByData(dataAlvo).single.entrada, '11:00');
      expect(provider.getTurnosByData(outroDia), hasLength(1));
      expect(provider.getTurnosByData(outroDia).single.id, 'mantem-outro-dia');
      expect(upserts, hasLength(1));
      expect(upserts.single, hasLength(1));
    });
  });
}
