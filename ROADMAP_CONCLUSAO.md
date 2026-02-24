# 🗺️ ROADMAP PARA CONCLUSÃO - CISS FISCAL ASSISTANT

## 📊 STATUS ATUAL
**Completude:** ~75-80%
**Flutter Analyze:** ✅ 0 issues
**Última Atualização:** 16/02/2026

---

## 🎯 META: 100% EM 8-15 DIAS

---

## 📅 FASE 1: FUNCIONALIDADES CRÍTICAS (1-2 dias)

### DIA 1: Perfil e Configurações
**Objetivo:** Permitir que o fiscal gerencie sua conta

#### Tarefas:
1. **Criar ProfileScreen**
   - [ ] Layout com dados do fiscal
   - [ ] Edição de nome, telefone, loja
   - [ ] Troca de senha
   - [ ] Botão de logout
   - **Tempo:** 2-3h
   - **Arquivos:** `lib/presentation/screens/profile/profile_screen.dart`

2. **Adicionar rota no Dashboard**
   - [ ] Botão "Configurações" no AppBar
   - [ ] Navegação para ProfileScreen
   - **Tempo:** 30min

#### Entregável:
✅ Fiscal pode editar perfil e trocar senha

---

### DIA 2: Gestão Completa de Caixas
**Objetivo:** CRUD completo de caixas

#### Tarefas:
1. **Criar CaixaFormScreen**
   - [ ] Formulário de cadastro/edição
   - [ ] Campos: número, tipo, localização, observações
   - [ ] Validações
   - **Tempo:** 2-3h
   - **Arquivos:** `lib/presentation/screens/caixas/caixa_form_screen.dart`

2. **Adicionar ações na lista**
   - [ ] Botão "Adicionar Caixa"
   - [ ] Ação "Editar" em cada caixa
   - [ ] Ação "Deletar" com confirmação
   - **Tempo:** 1-2h

3. **Criar CaixaDetalheScreen (opcional)**
   - [ ] Histórico de alocações do caixa
   - [ ] Estatísticas de uso
   - **Tempo:** 2h

#### Entregável:
✅ Gestão completa de caixas funcional

---

## 📅 FASE 2: VALIDAÇÃO DOS MÓDULOS (2-3 dias)

### DIA 3-4: Formulários Completos
**Objetivo:** Sistema de formulários 100% funcional

#### Tarefas:
1. **Validar/Criar 10 Templates**
   - [ ] Solicitação de Produto em Falta
   - [ ] Reclamação de Cliente
   - [ ] Checklist Abertura
   - [ ] Checklist Fechamento
   - [ ] Registro de Ocorrência
   - [ ] Troca/Devolução
   - [ ] Avaliação de Fornecedor
   - [ ] Controle de Temperatura
   - [ ] Vistoria de Segurança
   - [ ] Avaliação de Colaborador
   - **Tempo:** 3-4h

2. **Criar FormularioEditorScreen**
   - [ ] Adicionar/remover campos
   - [ ] 11 tipos de campos suportados
   - [ ] Reordenar campos
   - [ ] Preview do formulário
   - **Tempo:** 4-5h

3. **Criar FormularioPreenchimentoScreen**
   - [ ] Renderização dinâmica por tipo de campo
   - [ ] Validações automáticas
   - [ ] Salvar resposta
   - **Tempo:** 3-4h

4. **Criar FormularioRespostasScreen**
   - [ ] Lista de respostas por formulário
   - [ ] Visualizar resposta detalhada
   - [ ] Filtros por data
   - [ ] Exportar (futuro)
   - **Tempo:** 2-3h

5. **Criar Tabela no Supabase**
   - [ ] Tabela `formularios`
   - [ ] Tabela `respostas_formularios`
   - [ ] Policies RLS
   - **Tempo:** 1-2h

#### Entregável:
✅ Sistema de formulários completo e testado

---

### DIA 5: Procedimentos CRUD Completo
**Objetivo:** Permitir criar/editar procedimentos

#### Tarefas:
1. **Criar ProcedimentoFormScreen**
   - [ ] Formulário de cadastro/edição
   - [ ] Adicionar passos dinamicamente
   - [ ] Escolher categoria
   - [ ] Tempo estimado
   - **Tempo:** 3-4h

2. **Criar ProcedimentoDetalheScreen**
   - [ ] Layout formatado
   - [ ] Passos numerados
   - [ ] Botão "Editar"
   - [ ] Botão "Favoritar"
   - **Tempo:** 2h

3. **Adicionar CRUD no Provider**
   - [ ] Método `addProcedimento`
   - [ ] Método `updateProcedimento`
   - [ ] Método `deleteProcedimento`
   - **Tempo:** 1-2h

#### Entregável:
✅ CRUD completo de procedimentos

---

### DIA 6: Entregas Avançadas
**Objetivo:** Filtros, status e gestão completa

#### Tarefas:
1. **Implementar 4 Status**
   - [ ] Separada (amarelo)
   - [ ] Em Rota (azul)
   - [ ] Entregue (verde)
   - [ ] Cancelada (vermelho)
   - **Tempo:** 1h

2. **Criar EntregaFormScreen**
   - [ ] Campos completos (NF, cliente, endereço, etc.)
   - [ ] 3 cidades: Baependi, Caxambu, Cruzília
   - [ ] Validações
   - **Tempo:** 2-3h

3. **Implementar Filtros**
   - [ ] Filtro por cidade
   - [ ] Filtro por status
   - [ ] Busca por NF ou nome
   - **Tempo:** 2h

4. **Criar EntregaDetalheScreen**
   - [ ] Dados completos
   - [ ] Botões de ação (marcar em rota, entregue, cancelar)
   - [ ] Timeline da entrega
   - **Tempo:** 2-3h

5. **Tabela Supabase**
   - [ ] Criar tabela `entregas`
   - [ ] Policies RLS
   - **Tempo:** 1h

#### Entregável:
✅ Sistema de entregas completo

---

## 📅 FASE 3: FUNCIONALIDADES AVANÇADAS (3-5 dias)

### DIA 7-8: Snapshot Avançado
**Objetivo:** IA de sugestões e detecção automática

#### Tarefas:
1. **Lógica de Detecção de Horário**
   - [ ] Comparar horário atual vs escala
   - [ ] Detectar atrasos automaticamente
   - [ ] Criar snapshot no horário certo
   - **Tempo:** 3-4h

2. **Sugestão de Substituição**
   - [ ] Algoritmo de priorização
   - [ ] Considerar departamento
   - [ ] Considerar disponibilidade
   - [ ] Bottom sheet com sugestões
   - **Tempo:** 4-5h

3. **Tabelas Supabase**
   - [ ] `snapshots_turno`
   - [ ] `presencas_colaborador`
   - [ ] Policies RLS
   - **Tempo:** 2h

4. **Integração com Escala**
   - [ ] Parser de escala → turnos
   - [ ] Salvar turnos no banco
   - [ ] Consultar turnos para snapshot
   - **Tempo:** 3-4h

#### Entregável:
✅ Snapshot inteligente funcional

---

### DIA 9: Notas Completas
**Objetivo:** 3 tipos de notas (anotação, tarefa, lembrete)

#### Tarefas:
1. **Implementar 3 Tipos**
   - [ ] Enum: anotacao, tarefa, lembrete
   - [ ] Campos específicos por tipo
   - [ ] Checkbox para tarefas
   - [ ] DateTime para lembretes
   - **Tempo:** 2-3h

2. **Criar NotaFormScreen**
   - [ ] Seletor de tipo
   - [ ] Campos dinâmicos
   - [ ] Marcar importante
   - **Tempo:** 2-3h

3. **Filtros e Busca**
   - [ ] Filtro por tipo
   - [ ] Filtro por status (pendente/concluída)
   - [ ] Ordenação
   - **Tempo:** 2h

4. **Notificações Programadas**
   - [ ] Integração com flutter_local_notifications
   - [ ] Agendar lembrete
   - [ ] Disparar no horário
   - **Tempo:** 3-4h

#### Entregável:
✅ Sistema de notas completo

---

### DIA 10-11: Histórico e Relatórios
**Objetivo:** Visualizações de dados históricos

#### Tarefas:
1. **HistoricoAlocacoesScreen**
   - [ ] Lista cronológica
   - [ ] Filtro por colaborador
   - [ ] Filtro por caixa
   - [ ] Filtro por data
   - **Tempo:** 3-4h

2. **RelatorioScreen**
   - [ ] Estatísticas de alocações
   - [ ] Tempo médio por caixa
   - [ ] Colaborador mais alocado
   - [ ] Gráficos (fl_chart)
   - **Tempo:** 4-5h

3. **ColaboradorDetalheScreen**
   - [ ] Ficha completa
   - [ ] Histórico de alocações
   - [ ] Estatísticas individuais
   - [ ] Editar colaborador
   - **Tempo:** 3-4h

4. **Exportação de Timeline**
   - [ ] Gerar PDF
   - [ ] Gerar CSV
   - [ ] Compartilhar
   - **Tempo:** 4-5h

#### Entregável:
✅ Históricos e relatórios funcionais

---

## 📅 FASE 4: TESTES E REFINAMENTOS (2-3 dias)

### DIA 12-13: Testes Completos
**Objetivo:** Validar todos os fluxos

#### Tarefas:
1. **Testar CRUD Completo**
   - [ ] Colaboradores
   - [ ] Caixas
   - [ ] Alocações
   - [ ] Entregas
   - [ ] Procedimentos
   - [ ] Formulários
   - [ ] Notas
   - **Tempo:** 4-5h

2. **Testar Fluxos Principais**
   - [ ] Fluxo de chegada ao trabalho
   - [ ] Fluxo de alocação
   - [ ] Fluxo de entregas
   - [ ] Fluxo de snapshot
   - [ ] Fluxo de intervalos
   - **Tempo:** 3-4h

3. **Teste Offline**
   - [ ] Usar sem internet
   - [ ] Validar queue de sync
   - [ ] Validar merge de dados
   - **Tempo:** 2-3h

4. **Correção de Bugs**
   - [ ] Listar todos os bugs encontrados
   - [ ] Priorizar por gravidade
   - [ ] Corrigir críticos
   - [ ] Corrigir médios
   - **Tempo:** 8-10h

#### Entregável:
✅ App estável e testado

---

### DIA 14: UX/UI e Performance
**Objetivo:** Melhorias visuais e otimização

#### Tarefas:
1. **Melhorias Visuais**
   - [ ] Loading states em todas as telas
   - [ ] Empty states com ilustrações
   - [ ] Feedbacks visuais (snackbars)
   - [ ] Animações suaves
   - **Tempo:** 4-5h

2. **Otimizações**
   - [ ] Lazy loading de listas
   - [ ] Cache de imagens
   - [ ] Debounce em buscas
   - [ ] Pagination (se necessário)
   - **Tempo:** 3-4h

3. **Acessibilidade**
   - [ ] Semantic labels
   - [ ] Contrast ratios
   - [ ] Touch targets adequados
   - **Tempo:** 2-3h

#### Entregável:
✅ App polido e performático

---

## 📅 FASE 5: DEPLOY E TREINAMENTO (1-2 dias)

### DIA 15: Preparação para Produção
**Objetivo:** App pronto para uso real

#### Tarefas:
1. **Popular Dados Reais**
   - [ ] 25 colaboradores reais
   - [ ] Departamentos corretos
   - [ ] 11 caixas reais
   - [ ] Procedimentos validados
   - **Tempo:** 2-3h

2. **Documentação**
   - [ ] Manual do usuário
   - [ ] FAQ
   - [ ] Troubleshooting
   - **Tempo:** 3-4h

3. **Treinamento**
   - [ ] Criar vídeos tutoriais (opcional)
   - [ ] Treinar fiscal presencialmente
   - [ ] Acompanhar primeiro uso
   - **Tempo:** 2-4h

4. **Deploy**
   - [ ] Build release APK
   - [ ] Testar em produção
   - [ ] Monitorar primeiro dia
   - **Tempo:** 2-3h

#### Entregável:
✅ App em produção com usuário treinado

---

## 📊 RESUMO DO ROADMAP

### Tempo Total Estimado: 8-15 dias

| Fase | Dias | Foco | Status |
|------|------|------|--------|
| Fase 1 | 1-2 | Funcionalidades Críticas | ⏳ Pendente |
| Fase 2 | 2-3 | Validação dos Módulos | ⏳ Pendente |
| Fase 3 | 3-5 | Funcionalidades Avançadas | ⏳ Pendente |
| Fase 4 | 2-3 | Testes e Refinamentos | ⏳ Pendente |
| Fase 5 | 1-2 | Deploy e Treinamento | ⏳ Pendente |

---

## 🎯 PRIORIZAÇÃO

### Se tiver POUCO tempo (Mínimo Viável):
1. ✅ Fase 1 (Críticas)
2. ✅ Fase 2 (Validação - apenas formulários e procedimentos)
3. ✅ Fase 4 (Testes básicos)
4. ✅ Fase 5 (Deploy)

**Tempo:** ~5-7 dias

### Se tiver TEMPO MÉDIO (Recomendado):
1. ✅ Fase 1 (Críticas)
2. ✅ Fase 2 (Validação completa)
3. ✅ Fase 3 (Snapshot e Notas)
4. ✅ Fase 4 (Testes completos)
5. ✅ Fase 5 (Deploy)

**Tempo:** ~8-12 dias

### Se tiver MAIS TEMPO (Ideal):
1. ✅ Todas as 5 fases completas
2. ✅ Funcionalidades extras
3. ✅ Polimento adicional

**Tempo:** ~12-15 dias

---

## 📝 NOTAS IMPORTANTES

### Já Está Funcionando (Não precisa refazer):
- ✅ Autenticação
- ✅ Dashboard
- ✅ Seed de caixas
- ✅ Seed de procedimentos
- ✅ Correção de alocação
- ✅ Estrutura de providers
- ✅ Integração Supabase

### Precisa Atenção Especial:
- ⚠️ Snapshot (lógica complexa)
- ⚠️ Formulários (muitos tipos de campos)
- ⚠️ Notificações programadas
- ⚠️ Sincronização offline

### Pode Ser Feito Depois (V2):
- 📸 Foto de comprovante de entrega
- 🔔 FCM para notificações push
- 📊 Gráficos avançados
- 🗺️ Mapa real com GPS
- 📱 App iOS

---

## 🚀 COMEÇANDO AGORA

### Primeira tarefa (se escolher começar):
```bash
# Criar tela de perfil
mkdir -p lib/presentation/screens/profile
touch lib/presentation/screens/profile/profile_screen.dart
```

Quer que eu implemente alguma dessas fases agora? 😊
