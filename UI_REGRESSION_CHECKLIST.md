# Checklist Visual De Regressao UI

Use esta lista antes de fechar uma rodada de refatoracao visual.

## Navegacao Principal

- [ ] Abrir o app em celular e confirmar `NavigationBar` inferior sem quebra de texto.
- [ ] Abrir em tablet/web e confirmar sidebar/rail com selecao visivel.
- [ ] Alternar entre Inicio, Pizzaria, Operacoes, Loja e Balcao sem perder estado.

## Dashboard

- [ ] Confirmar que a Central do Turno mostra fiscal, status e acao principal.
- [ ] Verificar indicadores do turno em celular, tablet e web.
- [ ] Confirmar que alertas criticos aparecem com cor e acao correta.
- [ ] Testar monitor operacional com caixas, pausas e escala.

## Telas Criticas

- [ ] Mapa de caixas: verificar filtros, busca, metricas e secoes por localizacao.
- [ ] Alocacao: verificar metricas, busca, disponiveis, alocados, outro setor e folgas.
- [ ] Cafe: verificar disponiveis, em pausa, atrasos e historico.
- [ ] Balcao Fiscal: verificar loading, erro, vazio, filtros e lista de eventos.

## Estados E Textos

- [ ] Confirmar empty/loading/error states com o mesmo estilo visual.
- [ ] Verificar textos longos em telas pequenas.
- [ ] Conferir contraste de texto em chips, metricas e banners.
- [ ] Confirmar que botoes com icones mantem tamanho estavel.

## Regressao Funcional

- [ ] Rodar `flutter analyze`.
- [ ] Rodar `flutter test`.
- [ ] Abrir a previa web e confirmar que responde em `http://127.0.0.1:5180`.
