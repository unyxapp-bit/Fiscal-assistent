# Widgets do Módulo Caixas V3

Esta pasta foi criada para receber os widgets hoje concentrados em `gestao_screen.dart`.

## Ordem segura de extração

1. `CaixasHeroHeader`
2. `CaixasSummaryGrid`
3. `ActionGrid` e `CentralAction`
4. `MiniPauseQueue`
5. `MiniCashierMap`
6. `MiniBottleneckPanel`
7. `CaixasSidebarV3`
8. `GestaoTopNavigation`

## Regra importante

Antes de mover uma classe para outro arquivo, remova o `_` do nome dela dentro de `gestao_screen.dart`.

Exemplo:

```dart
_CaixasHeroHeader -> CaixasHeroHeader
```

Classes privadas em Dart só funcionam dentro do mesmo arquivo.

## Objetivo

Reduzir `gestao_screen.dart`, separar responsabilidades e preparar a próxima fase visual do módulo Caixas.
