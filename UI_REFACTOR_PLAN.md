# Plano de Refatoracao UI/Layout

## Objetivo

Transformar o Fiscal Assistant em uma central operacional mais profissional, rapida de ler e consistente em celular, tablet e web, mantendo as regras de negocio e os providers atuais.

O foco visual deve ser menos "cards decorativos" e mais painel de trabalho: informacao densa, estados claros, acoes previsiveis e navegacao estavel durante o turno.

## Diagnostico Inicial

- O app ja tem uma boa base de tema central em `lib/core/theme/app_theme.dart`.
- A UI usa muitos tokens proprios (`AppColors`, `AppTextStyles`, `Dimensions`, `AppStyles`), o que permite uma mudanca global eficiente.
- A tela inicial concentra muita responsabilidade: `dashboard_screen.dart` tem mais de 2800 linhas.
- Outras telas criticas tambem sao grandes: mapa de caixas, balcao fiscal, alocacao, cafe e colaborador detalhado.
- Ha navegacao espalhada com `Navigator.push` e `MaterialPageRoute`, o que dificulta padronizar fluxo, titulos, acoes e responsividade.
- O visual atual tem raios grandes, blocos muito separados e dois temas com linguagem diferente demais para um app operacional.

## Direcao Visual

### Estilo

- Central operacional de supermercado.
- Visual limpo, utilitario e robusto.
- Densidade moderada: mostrar mais contexto sem parecer apertado.
- Cards com raio menor, bordas discretas e sombras quase imperceptiveis.
- Status por cor com semantica forte, nao por decoracao.

### Paleta

- Base neutra clara com superficies brancas e cinzas frios.
- Primaria em verde/teal operacional.
- Azul para informacao.
- Amarelo/ambar para atencao.
- Vermelho para erro, atraso e risco.
- Verde para sucesso/ok.
- Evitar tema de uma cor so e evitar gradientes dominantes.

### Tipografia

- Titulos mais compactos.
- Sem escala exagerada em paines internos.
- Sem letter spacing negativo.
- Labels e numeros com pesos fortes para leitura rapida.

## Arquitetura de UI Alvo

### 1. Fundacao Global

- Atualizar `AppThemeTokens` para a nova linguagem visual.
- Compactar raios, paddings e estilos de botao.
- Ajustar `CardTheme`, `InputDecorationTheme`, `NavigationBarTheme`, `NavigationRail`, `TabBar` e `SnackBar`.
- Manter compatibilidade com `AppColors`, `AppTextStyles`, `Dimensions` e `AppStyles`.

### 2. Shell do App

- Criar uma navegacao principal mais consistente.
- Celular: `NavigationBar` inferior para secoes principais.
- Tablet/web: sidebar/rail expandido com identidade do fiscal e acoes globais.
- Separar o shell da logica do dashboard em uma etapa posterior.

### 3. Dashboard Novo

- Reorganizar a home como "Central do Turno".
- Topo com fiscal, saudacao, estado do turno e acao principal.
- Bloco de saude operacional com alertas acionaveis.
- Monitor em tempo real com caixas, colaboradores, pausas e escala.
- Acoes rapidas agrupadas por rotina: Operacao, Loja, Registro e Ferramentas.
- Cards de metricas mais compactos e alinhados.

### 4. Componentes Compartilhados

Criar ou consolidar:

- `AppPage`
- `AppSection`
- `AppSurface`
- `MetricTile`
- `StatusPill`
- `ActionTile`
- `ModuleShortcut`
- `ResponsiveContent`
- `OperationalEmptyState`

### 5. Migracao Por Modulo

Ordem sugerida:

1. Dashboard e shell principal.
2. Mapa de caixas.
3. Alocacao.
4. Cafe/intervalos.
5. Balcao Fiscal.
6. Colaboradores.
7. Notas, checklist, entregas e procedimentos.
8. Pizzaria e cartazes.
9. Telas de formulario/configuracao.

## Plano de Execucao

### Fase 1 - Base Visual

- [x] Atualizar tema global para o visual operacional.
- [x] Reduzir raios, sombras e excesso visual.
- [x] Padronizar navegacao principal responsiva.
- [x] Rodar `dart format` e `flutter analyze`.

### Fase 2 - Dashboard

- [x] Quebrar `dashboard_screen.dart` em widgets menores.
- [x] Extrair destinos de navegacao em modelo unico.
- [x] Migrar cabecalhos, status, metricas e acoes para componentes compartilhados.
- [x] Redesenhar header, metricas, alertas e acoes rapidas.
- [x] Revisar responsividade em celular e tablet.

### Fase 3 - Componentes

- [x] Criar componentes comuns para secoes, status, metricas e acoes.
- [x] Migrar `StatsCard` do dashboard e botoes de acao principais.
- [x] Padronizar estados vazios.
- [x] Remover duplicacoes de estilos inline principais.

### Fase 4 - Telas Criticas

- [x] Mapa de caixas: foco em leitura imediata do status.
- [x] Alocacao: fluxo de escolha mais direto.
- [x] Cafe: filas claras por estado e atraso.
- [x] Balcao Fiscal: inbox operacional com triagem rapida.

### Fase 5 - Polimento

- [x] Revisar contraste e acessibilidade.
- [x] Verificar textos longos em telas pequenas.
- [x] Padronizar empty/loading/error states.
- [x] Criar checklist visual para regressao manual.

## Criterios De Pronto

- O app abre com uma identidade visual unica e profissional.
- As secoes principais sao acessiveis por uma navegacao previsivel.
- A tela inicial comunica o estado do turno em poucos segundos.
- Componentes comuns reduzem duplicacao e deixam as proximas telas mais faceis de migrar.
- `flutter analyze` nao introduz novos erros relacionados a refatoracao.

## Primeira Fatia

Comecar pela Fase 1:

- Atualizar tema global.
- Ajustar `AppStyles`.
- Trocar a navegacao mobile do dashboard de `TabBar` no AppBar para `NavigationBar` inferior.
- Melhorar o rail em tablet/web para parecer uma sidebar operacional.
