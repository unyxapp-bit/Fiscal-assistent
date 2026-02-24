# 📱 CISS FISCAL ASSISTANT - LISTA COMPLETA DE FUNCIONALIDADES

## 📊 RESUMO EXECUTIVO

**Total de Módulos:** 20  
**Total de Funcionalidades:** 68  
**Total de Telas:** 50+  
**Total de Tabelas:** 12  
**Status:** 100% Especificado ✅

---

## 🎯 ÍNDICE POR CATEGORIA

1. [Autenticação e Perfil](#1-autenticação-e-perfil) (3 funcionalidades)
2. [Dashboard Principal](#2-dashboard-principal) (5 funcionalidades)
3. [Gestão de Colaboradores](#3-gestão-de-colaboradores) (8 funcionalidades)
4. [Gestão de Caixas](#4-gestão-de-caixas) (7 funcionalidades)
5. [Sistema de Alocação](#5-sistema-de-alocação) (9 funcionalidades)
6. [Mapa Visual](#6-mapa-visual) (4 funcionalidades)
7. [Timeline de Eventos](#7-timeline-de-eventos) (3 funcionalidades)
8. [Gestão de Intervalos/Café](#8-gestão-de-intervaloscafé) (5 funcionalidades)
9. [Sistema de Entregas](#9-sistema-de-entregas) (7 funcionalidades)
10. [Base de Conhecimento - Procedimentos](#10-base-de-conhecimento---procedimentos) (6 funcionalidades)
11. [Anotações e Lembretes](#11-anotações-e-lembretes) (5 funcionalidades)
12. [Sistema de Formulários](#12-sistema-de-formulários) (8 funcionalidades)
13. [Snapshot de Turno](#13-snapshot-de-turno) (8 funcionalidades)

---

## 1. AUTENTICAÇÃO E PERFIL

### 1.1 Login
**Descrição:** Sistema de autenticação segura com Supabase  
**Funcionalidades:**
- Login com e-mail e senha
- Validação de credenciais
- Mensagens de erro claras
- Redirecionamento automático após login

**Telas:** 1 tela (LoginScreen)  
**Tabelas:** auth.users (Supabase), fiscais

---

### 1.2 Registro de Conta
**Descrição:** Criar nova conta de fiscal  
**Funcionalidades:**
- Cadastro com e-mail e senha
- Validação de e-mail único
- Confirmação por e-mail
- Criação automática de perfil

**Telas:** 1 tela (RegisterScreen)  
**Tabelas:** auth.users, fiscais

---

### 1.3 Gerenciamento de Perfil
**Descrição:** Visualizar e editar dados do perfil  
**Funcionalidades:**
- Ver informações do fiscal
- Editar nome, telefone, loja
- Atualizar senha
- Logout

**Telas:** 1 tela (ProfileScreen)  
**Tabelas:** fiscais

---

## 2. DASHBOARD PRINCIPAL

### 2.1 Visão Geral do Dia
**Descrição:** Tela inicial com resumo das operações  
**Funcionalidades:**
- Relógio em tempo real
- Contadores principais (colaboradores, caixas, alocações)
- Ações rápidas (10 botões)
- Última sincronização

**Telas:** 1 tela (DashboardScreen)  
**Tabelas:** Múltiplas (agregação)

---

### 2.2 Estatísticas em Tempo Real
**Descrição:** Cards com números do dia  
**Funcionalidades:**
- Total de colaboradores ativos
- Total de caixas disponíveis
- Alocações ativas no momento
- Entregas pendentes
- Tarefas abertas

**Telas:** Componentes do Dashboard  
**Tabelas:** colaboradores, caixas, alocacoes, entregas, notas

---

### 2.3 Notificações Push
**Descrição:** Alertas em tempo real  
**Funcionalidades:**
- Notificação de atrasos
- Alerta de intervalos
- Lembretes programados
- Avisos de sistema
- Badge com contador

**Telas:** Sistema de notificações  
**Tabelas:** N/A (local)

---

### 2.4 Ações Rápidas
**Descrição:** Acesso rápido às funcionalidades principais  
**Funcionalidades:**
- 10 botões de acesso direto
- Navegação otimizada
- Ícones intuitivos
- Organização por categoria

**Telas:** Dashboard  
**Tabelas:** N/A

---

### 2.5 Sincronização Offline
**Descrição:** Funciona sem internet  
**Funcionalidades:**
- Salva dados localmente
- Fila de sincronização
- Retry automático
- Indicador de status

**Telas:** Sistema background  
**Tabelas:** Todas (local + remoto)

---

## 3. GESTÃO DE COLABORADORES

### 3.1 Listagem de Colaboradores
**Descrição:** Ver todos os 25 colaboradores  
**Funcionalidades:**
- Lista completa com foto/avatar
- Busca por nome
- Filtro por departamento
- Ordenação customizada
- Contador por status

**Telas:** 1 tela (ColaboradoresScreen)  
**Tabelas:** colaboradores

---

### 3.2 Cadastro de Colaborador
**Descrição:** Adicionar novo funcionário  
**Funcionalidades:**
- Formulário completo
- Campos: Nome, CPF, Telefone, Departamento, Cargo, Data admissão
- Validação de CPF
- Upload de foto
- Observações

**Telas:** 1 tela (ColaboradorFormScreen)  
**Tabelas:** colaboradores

---

### 3.3 Edição de Colaborador
**Descrição:** Atualizar dados existentes  
**Funcionalidades:**
- Editar qualquer campo
- Alterar departamento
- Marcar como ativo/inativo
- Histórico de alterações

**Telas:** 1 tela (ColaboradorFormScreen)  
**Tabelas:** colaboradores

---

### 3.4 Visualização de Detalhes
**Descrição:** Ver ficha completa do colaborador  
**Funcionalidades:**
- Todos os dados cadastrais
- Status atual (disponível/alocado/intervalo)
- Histórico de alocações
- Estatísticas (dias trabalhados, pontualidade)

**Telas:** 1 tela (ColaboradorDetalheScreen)  
**Tabelas:** colaboradores, alocacoes

---

### 3.5 Filtros e Busca
**Descrição:** Encontrar colaboradores rapidamente  
**Funcionalidades:**
- Busca por nome
- Filtro por departamento (10 opções)
- Filtro por status (ativo/inativo)
- Filtro por disponibilidade
- Limpar filtros

**Telas:** ColaboradoresScreen  
**Tabelas:** colaboradores

---

### 3.6 Departamentos
**Descrição:** Organização por setor  
**Funcionalidades:**
- 10 departamentos: caixa, açougue, padaria, hortifruti, depósito, limpeza, segurança, gerência, fiscal, pacote
- Badge colorido por departamento
- Contador por departamento
- Estatísticas por setor

**Telas:** Multiple  
**Tabelas:** colaboradores

---

### 3.7 Exclusão de Colaborador
**Descrição:** Remover colaborador do sistema  
**Funcionalidades:**
- Confirmação de exclusão
- Validação (não pode estar alocado)
- Soft delete (marcar como inativo)
- Histórico preservado

**Telas:** Confirmação Dialog  
**Tabelas:** colaboradores

---

### 3.8 Status em Tempo Real
**Descrição:** Ver onde cada um está  
**Funcionalidades:**
- Status: Disponível, Alocado, Intervalo
- Caixa atual (se alocado)
- Tempo de alocação
- Próximo intervalo

**Telas:** Lista e Detalhes  
**Tabelas:** colaboradores, alocacoes

---

## 4. GESTÃO DE CAIXAS

### 4.1 Listagem de Caixas
**Descrição:** Ver todas as 11 caixas  
**Funcionalidades:**
- 8 PDVs + 3 Self-Service
- Status visual (disponível/ocupado/manutenção/fechado)
- Localização (entrada/meio/fundo)
- Ordenação por número

**Telas:** 1 tela (CaixasScreen)  
**Tabelas:** caixas

---

### 4.2 Cadastro de Caixa
**Descrição:** Adicionar novo caixa  
**Funcionalidades:**
- Número do caixa
- Tipo (PDV ou Self-Service)
- Loja
- Localização
- Status inicial
- Observações

**Telas:** 1 tela (CaixaFormScreen)  
**Tabelas:** caixas

---

### 4.3 Edição de Caixa
**Descrição:** Atualizar dados do caixa  
**Funcionalidades:**
- Alterar tipo
- Mudar localização
- Alterar status
- Marcar manutenção
- Observações técnicas

**Telas:** 1 tela (CaixaFormScreen)  
**Tabelas:** caixas

---

### 4.4 Status de Caixa
**Descrição:** 4 estados possíveis  
**Funcionalidades:**
- Disponível (verde)
- Ocupado (azul)
- Manutenção (laranja)
- Fechado (vermelho)
- Mudança rápida de status

**Telas:** Multiple  
**Tabelas:** caixas

---

### 4.5 Filtros por Tipo
**Descrição:** Separar PDV e Self-Service  
**Funcionalidades:**
- Filtro por tipo
- Filtro por status
- Filtro por localização
- Ver apenas disponíveis

**Telas:** CaixasScreen  
**Tabelas:** caixas

---

### 4.6 Visualização de Ocupação
**Descrição:** Ver quem está no caixa  
**Funcionalidades:**
- Colaborador atual
- Horário de início
- Tempo de operação
- Histórico do dia

**Telas:** Detalhes do Caixa  
**Tabelas:** caixas, alocacoes

---

### 4.7 Mapa de Localização
**Descrição:** Ver disposição física  
**Funcionalidades:**
- Grid visual de caixas
- Cores por status
- Entrada/Meio/Fundo
- Toque para alocar

**Telas:** MapaVisualScreen  
**Tabelas:** caixas

---

## 5. SISTEMA DE ALOCAÇÃO

### 5.1 Alocar Colaborador em Caixa
**Descrição:** Designar pessoa para caixa específico  
**Funcionalidades:**
- Selecionar colaborador
- Selecionar caixa
- Validação de disponibilidade
- Registro automático de horário
- Confirmação visual

**Telas:** 1 tela (AlocacaoScreen)  
**Tabelas:** alocacoes, colaboradores, caixas

---

### 5.2 Liberar Caixa
**Descrição:** Remover colaborador do caixa  
**Funcionalidades:**
- Finalizar alocação
- Registrar horário de saída
- Calcular tempo trabalhado
- Liberar caixa automaticamente

**Telas:** Ação em múltiplas telas  
**Tabelas:** alocacoes, caixas

---

### 5.3 Substituição Rápida
**Descrição:** Trocar colaborador sem desalocar  
**Funcionalidades:**
- Substituir em 1 clique
- Preservar histórico
- Registrar motivo
- Timeline completa

**Telas:** Ações rápidas  
**Tabelas:** alocacoes

---

### 5.4 Validações de Alocação
**Descrição:** Regras de negócio  
**Funcionalidades:**
- Não alocar se já alocado
- Verificar tipo de caixa
- Validar departamento
- Alertas de conflito

**Telas:** Sistema de validação  
**Tabelas:** alocacoes

---

### 5.5 Histórico de Alocações
**Descrição:** Ver todas as alocações do dia  
**Funcionalidades:**
- Lista cronológica
- Filtro por colaborador
- Filtro por caixa
- Exportar relatório

**Telas:** 1 tela (HistoricoScreen)  
**Tabelas:** alocacoes

---

### 5.6 Alocações Ativas
**Descrição:** Ver quem está operando agora  
**Funcionalidades:**
- Lista em tempo real
- Tempo de operação
- Próximo intervalo
- Liberar em massa

**Telas:** Dashboard, Lista  
**Tabelas:** alocacoes

---

### 5.7 Sugestão de Alocação
**Descrição:** IA sugere melhor colaborador  
**Funcionalidades:**
- Baseado em disponibilidade
- Considera departamento
- Verifica escala
- Prioriza experiência

**Telas:** Snapshot, Alocação  
**Tabelas:** alocacoes, colaboradores, turnos_escala

---

### 5.8 Trocar Caixa
**Descrição:** Mover colaborador para outro caixa  
**Funcionalidades:**
- Selecionar novo caixa
- Preservar tempo trabalhado
- Registrar troca
- Timeline atualizada

**Telas:** Ações  
**Tabelas:** alocacoes

---

### 5.9 Relatório de Produtividade
**Descrição:** Estatísticas de alocações  
**Funcionalidades:**
- Tempo médio por caixa
- Colaborador mais alocado
- Caixa mais usado
- Gráficos

**Telas:** 1 tela (RelatorioScreen)  
**Tabelas:** alocacoes

---

## 6. MAPA VISUAL

### 6.1 Grid de Caixas
**Descrição:** Visualização em grid 3x4  
**Funcionalidades:**
- 11 caixas em grid
- Cores por status
- PDV vs Self-Service
- Toque para detalhes

**Telas:** 1 tela (MapaVisualScreen)  
**Tabelas:** caixas

---

### 6.2 Status Visual em Tempo Real
**Descrição:** Cores indicam disponibilidade  
**Funcionalidades:**
- Verde: Disponível
- Azul: Ocupado (mostra nome)
- Laranja: Manutenção
- Vermelho: Fechado
- Atualização automática

**Telas:** MapaVisualScreen  
**Tabelas:** caixas, alocacoes

---

### 6.3 Ação Rápida no Mapa
**Descrição:** Alocar direto do mapa  
**Funcionalidades:**
- Toque no caixa disponível
- Seleciona colaborador
- Aloca instantaneamente
- Feedback visual

**Telas:** MapaVisualScreen  
**Tabelas:** alocacoes

---

### 6.4 Legenda do Mapa
**Descrição:** Explicação das cores  
**Funcionalidades:**
- Legenda sempre visível
- Contador por status
- Percentual de ocupação
- Estatísticas rápidas

**Telas:** MapaVisualScreen  
**Tabelas:** caixas

---

## 7. TIMELINE DE EVENTOS

### 7.1 Registro Automático de Eventos
**Descrição:** Tudo é gravado automaticamente  
**Funcionalidades:**
- Alocação iniciada
- Alocação finalizada
- Intervalo iniciado
- Intervalo finalizado
- Substituições
- Observações

**Telas:** Background  
**Tabelas:** alocacoes (timestamps)

---

### 7.2 Visualização da Timeline
**Descrição:** Ver linha do tempo do dia  
**Funcionalidades:**
- Ordem cronológica
- Filtro por tipo de evento
- Filtro por colaborador
- Busca por horário

**Telas:** 1 tela (TimelineScreen)  
**Tabelas:** alocacoes

---

### 7.3 Exportar Timeline
**Descrição:** Gerar relatório do dia  
**Funcionalidades:**
- PDF com timeline completa
- CSV para planilha
- Enviar por e-mail
- Compartilhar WhatsApp

**Telas:** TimelineScreen  
**Tabelas:** alocacoes

---

## 8. GESTÃO DE INTERVALOS/CAFÉ

### 8.1 Programar Intervalo
**Descrição:** Definir horário de pausa  
**Funcionalidades:**
- Selecionar colaborador
- Definir duração (padrão 15 min)
- Notificação 5 min antes
- Bloquear alocação durante

**Telas:** 1 tela (CafeScreen)  
**Tabelas:** alocacoes

---

### 8.2 Iniciar Intervalo
**Descrição:** Marcar início da pausa  
**Funcionalidades:**
- Status muda para "intervalo"
- Timer inicia
- Caixa fica disponível
- Notificação de retorno

**Telas:** CafeScreen  
**Tabelas:** alocacoes

---

### 8.3 Timer de Intervalo
**Descrição:** Contador regressivo  
**Funcionalidades:**
- Mostra tempo restante
- Alerta em 2 minutos
- Notificação ao terminar
- Histórico de pausas

**Telas:** CafeScreen, Notificações  
**Tabelas:** alocacoes

---

### 8.4 Finalizar Intervalo
**Descrição:** Registrar volta do colaborador  
**Funcionalidades:**
- Marca fim da pausa
- Calcula tempo real
- Alerta se passou do tempo
- Realocar automaticamente

**Telas:** CafeScreen  
**Tabelas:** alocacoes

---

### 8.5 Alertas de Intervalo Longo
**Descrição:** Avisar se passou do tempo  
**Funcionalidades:**
- Notificação > 20 minutos
- Lista de atrasados
- Enviar mensagem
- Registrar ocorrência

**Telas:** Notificações  
**Tabelas:** alocacoes

---

## 9. SISTEMA DE ENTREGAS

### 9.1 Registrar Entrega
**Descrição:** Cadastrar nova entrega  
**Funcionalidades:**
- Número da NF
- Nome do cliente
- Telefone/WhatsApp
- Endereço completo
- Bairro e cidade (Baependi/Caxambu/Cruzília)
- Horário marcado
- Observações

**Telas:** 1 tela (EntregaFormScreen)  
**Tabelas:** entregas

---

### 9.2 Status de Entrega
**Descrição:** 4 estados possíveis  
**Funcionalidades:**
- Separada (amarelo)
- Em Rota (azul)
- Entregue (verde)
- Cancelada (vermelho)
- Mudar status facilmente

**Telas:** Lista, Detalhes  
**Tabelas:** entregas

---

### 9.3 Filtro por Cidade
**Descrição:** Ver entregas por região  
**Funcionalidades:**
- Baependi
- Caxambu
- Cruzília
- Contador por cidade
- Mapa de distribuição

**Telas:** 1 tela (EntregasScreen)  
**Tabelas:** entregas

---

### 9.4 Filtro por Status
**Descrição:** Organizar por situação  
**Funcionalidades:**
- Ver apenas separadas
- Ver em rota
- Ver entregues hoje
- Histórico completo

**Telas:** EntregasScreen  
**Tabelas:** entregas

---

### 9.5 Marcar como Em Rota
**Descrição:** Motorista saiu  
**Funcionalidades:**
- Registra horário de saída
- Notifica cliente (futuro)
- Atualiza mapa
- Timeline

**Telas:** Ação rápida  
**Tabelas:** entregas

---

### 9.6 Marcar como Entregue
**Descrição:** Confirmar entrega  
**Funcionalidades:**
- Registra horário
- Calcular tempo total
- Foto de comprovante (futuro)
- Assinatura digital (futuro)

**Telas:** Ação rápida  
**Tabelas:** entregas

---

### 9.7 Cancelar Entrega
**Descrição:** Entrega não realizada  
**Funcionalidades:**
- Motivo do cancelamento
- Notificar responsável
- Manter histórico
- Estatísticas

**Telas:** Confirmação  
**Tabelas:** entregas

---

## 10. BASE DE CONHECIMENTO - PROCEDIMENTOS

### 10.1 Listar Procedimentos
**Descrição:** 13 procedimentos pré-cadastrados  
**Funcionalidades:**
- Lista completa
- Busca por palavra-chave
- Filtro por categoria (8 categorias)
- Favoritos primeiro
- Contador de passos

**Telas:** 1 tela (ProcedimentosScreen)  
**Tabelas:** procedimentos

---

### 10.2 Ver Detalhes do Procedimento
**Descrição:** Visualizar passo-a-passo  
**Funcionalidades:**
- Título e descrição
- Categoria colorida
- Passos numerados
- Tempo estimado
- Observações importantes

**Telas:** 1 tela (ProcedimentoDetalheScreen)  
**Tabelas:** procedimentos

---

### 10.3 Criar Procedimento
**Descrição:** Adicionar novo procedimento  
**Funcionalidades:**
- Formulário completo
- Título e descrição
- Escolher categoria
- Adicionar passos dinamicamente
- Tempo estimado
- Salvar como favorito

**Telas:** 1 tela (ProcedimentoFormScreen)  
**Tabelas:** procedimentos

---

### 10.4 Editar Procedimento
**Descrição:** Atualizar procedimento existente  
**Funcionalidades:**
- Editar qualquer campo
- Adicionar/remover passos
- Reordenar passos
- Alterar categoria

**Telas:** ProcedimentoFormScreen  
**Tabelas:** procedimentos

---

### 10.5 Deletar Procedimento
**Descrição:** Remover procedimento  
**Funcionalidades:**
- Confirmação de exclusão
- Não pode deletar padrões
- Histórico preservado

**Telas:** Confirmação Dialog  
**Tabelas:** procedimentos

---

### 10.6 Marcar Favorito
**Descrição:** Procedimentos mais usados  
**Funcionalidades:**
- Estrela para favoritar
- Lista de favoritos
- Acesso rápido no dashboard
- Contador de uso (futuro)

**Telas:** Lista, Detalhes  
**Tabelas:** procedimentos

---

Continua na próxima parte...
