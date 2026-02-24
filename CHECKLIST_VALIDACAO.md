# ✅ CHECKLIST DE VALIDAÇÃO - CISS FISCAL ASSISTANT

Use este checklist para testar cada funcionalidade do app.

---

## 🔐 AUTENTICAÇÃO (3/3)
- [ ] Login com email e senha funciona
- [ ] Registro de nova conta funciona
- [ ] Logout funciona corretamente

---

## 📊 DASHBOARD (5/5)
- [x] Relógio em tempo real aparece
- [x] Cards de estatísticas mostram números corretos
- [x] Pull to refresh funciona
- [x] 20 botões de ações rápidas aparecem
- [x] Navegação para outras telas funciona

---

## 👥 COLABORADORES (8/8)
- [ ] Lista mostra todos os colaboradores
- [ ] Busca por nome funciona
- [ ] Filtro por departamento funciona
- [ ] Cadastro de novo colaborador salva no banco
- [ ] Edição de colaborador funciona
- [ ] Excluir colaborador funciona
- [ ] Status em tempo real atualiza
- [ ] Tela de status mostra corretamente

---

## 🏪 CAIXAS (7/7)
- [x] 8 caixas aparecem automaticamente (seed)
- [ ] Lista mostra todas as caixas
- [ ] Status visual (cores) correto
- [ ] Toggle ativo/inativo funciona
- [ ] Toggle manutenção funciona
- [ ] Filtros funcionam
- [ ] Mapa visual mostra grid correto

---

## 🔄 ALOCAÇÃO (9/9)
- [ ] Alocar colaborador em caixa funciona
- [ ] Validações bloqueiam alocações inválidas
- [ ] Liberar caixa funciona
- [ ] Substituição rápida funciona
- [ ] Lista de alocações ativas aparece
- [ ] Histórico de alocações mostra dados
- [ ] Timeline registra eventos
- [ ] Stats do dashboard atualizam em tempo real
- [ ] Trocar de caixa funciona

---

## 🗺️ MAPA VISUAL (4/4)
- [ ] Grid de caixas aparece corretamente
- [ ] Cores por status funcionam
- [ ] Clicar em caixa mostra detalhes
- [ ] Legenda está visível

---

## ⏱️ TIMELINE (3/3)
- [ ] Timeline mostra eventos em ordem cronológica
- [ ] Filtros funcionam
- [ ] Exportação funciona (se implementada)

---

## ☕ CAFÉ/INTERVALOS (5/5)
- [ ] Tela de café abre
- [ ] Programar intervalo funciona
- [ ] Iniciar intervalo atualiza status
- [ ] Timer de intervalo funciona
- [ ] Finalizar intervalo funciona

---

## 🚚 ENTREGAS (7/7)
- [ ] Tela de entregas abre
- [ ] Cadastrar entrega funciona
- [ ] 4 status aparecem corretamente
- [ ] Filtro por cidade funciona
- [ ] Filtro por status funciona
- [ ] Marcar "em rota" funciona
- [ ] Marcar "entregue" funciona

---

## 📚 PROCEDIMENTOS (6/6)
- [x] Lista mostra 9 procedimentos
- [x] Busca funciona
- [ ] Ver detalhes mostra passos numerados
- [ ] Criar novo procedimento funciona
- [ ] Editar procedimento funciona
- [ ] Marcar favorito funciona

---

## 📝 ANOTAÇÕES (5/5)
- [ ] Tela de notas abre
- [ ] Criar anotação funciona
- [ ] Criar tarefa funciona
- [ ] Criar lembrete funciona
- [ ] Editar/deletar funciona

---

## 📋 FORMULÁRIOS (8/8)
- [ ] Tela de formulários abre
- [ ] 10 templates aparecem
- [ ] Criar formulário personalizado funciona
- [ ] Editar formulário funciona
- [ ] Preencher formulário funciona
- [ ] Ver respostas funciona
- [ ] Deletar formulário funciona
- [ ] Estatísticas aparecem

---

## 📸 SNAPSHOT (8/8)
- [ ] Tela de snapshot abre
- [ ] Criar snapshot automático funciona
- [ ] Confirmar presença funciona
- [ ] Marcar ausência funciona
- [ ] Marcar atraso funciona
- [ ] Sugestão de substituição funciona
- [ ] Substituir colaborador funciona
- [ ] Finalizar snapshot funciona

---

## 🔔 NOTIFICAÇÕES (3/3)
- [ ] Tela de notificações abre
- [ ] Lista de notificações aparece
- [ ] Marcar como lida funciona

---

## 📅 IMPORTAR ESCALA (3/3)
- [ ] Tela abre corretamente
- [ ] Câmera/galeria funcionam
- [ ] OCR extrai texto da imagem

---

## 🏖️ MODO FOLGA (3/3)
- [ ] Tela mostra relógio
- [ ] Calcula próximo turno
- [ ] Botões de ações funcionam

---

## 🔧 FUNCIONALIDADES TÉCNICAS

### Database
- [x] Banco local (Drift) funciona
- [x] Seed de caixas automático funciona
- [ ] Sincronização com Supabase funciona
- [ ] Offline-first funciona (testar sem internet)

### Performance
- [x] App inicia sem crashes
- [x] Flutter analyze sem erros
- [ ] Navegação fluída entre telas
- [ ] Carregamento de listas rápido

### Segurança
- [ ] RLS do Supabase funciona (usuário só vê seus dados)
- [ ] Sessão persiste após fechar app
- [ ] Logout limpa dados sensíveis

---

## 📊 RESUMO

**Total de itens:** ~90
**Validados:** ✅ Marque conforme testa

### Status Atual:
- ✅ **FUNCIONANDO:** 15-20 itens
- ⚠️ **A TESTAR:** 60-70 itens
- ❌ **PENDENTE:** 5-10 itens

---

## 🎯 FLUXOS DE TESTE PRIORITÁRIOS

### FLUXO 1: Primeiro Uso
1. [ ] Instalar app
2. [ ] Criar conta
3. [ ] Fazer login
4. [ ] Ver dashboard
5. [ ] 8 caixas criadas automaticamente
6. [ ] Cadastrar 2-3 colaboradores de teste

### FLUXO 2: Operação Diária
1. [ ] Login
2. [ ] Ver dashboard atualizado
3. [ ] Alocar colaborador em caixa
4. [ ] Ver mapa visual atualizado
5. [ ] Liberar alocação
6. [ ] Ver timeline de eventos

### FLUXO 3: Gestão de Entregas
1. [ ] Abrir entregas
2. [ ] Cadastrar nova entrega
3. [ ] Mudar status para "em rota"
4. [ ] Mudar status para "entregue"
5. [ ] Ver filtros funcionando

### FLUXO 4: Consultar Procedimento
1. [ ] Abrir procedimentos
2. [ ] Buscar "fechamento"
3. [ ] Ver procedimento com passos
4. [ ] Marcar como favorito

### FLUXO 5: Snapshot de Turno
1. [ ] Abrir snapshot
2. [ ] Confirmar presença de colaborador
3. [ ] Marcar ausência de colaborador
4. [ ] Ver estatísticas atualizadas
5. [ ] Finalizar snapshot

---

**Dica:** Teste em um dispositivo real ou emulador. Anote bugs e comportamentos inesperados!
