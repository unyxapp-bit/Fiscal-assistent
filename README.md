# Fiscal Assistant

Assistente pessoal para **fiscais de caixa** de supermercados e lojas de varejo. O app centraliza toda a operação do turno em um único lugar: alocação de colaboradores, controle de intervalos, mapa de caixas, escala semanal, ocorrências, entregas e muito mais.

---

## Conceito Base

O **fiscal de caixa** é o responsável por gerenciar os operadores de caixa durante o turno. Seu trabalho envolve:

- Distribuir colaboradores nos caixas disponíveis ao longo do dia
- Controlar os intervalos e horários de saída de cada um
- Registrar ocorrências, entregas e pendências
- Fazer a passagem de turno para o próximo fiscal

Sem uma ferramenta adequada, tudo isso é feito de cabeça, em papel ou em planilhas dispersas. O **Fiscal Assistant** resolve isso com um sistema integrado que acompanha o turno em tempo real, registra todos os eventos automaticamente na timeline e centraliza as informações do dia.

---

## Arquitetura

```
Flutter (Material Design 3)
    └── Provider (gerenciamento de estado)
            └── Supabase (banco de dados e autenticação em nuvem)
```

Cada fiscal tem seus próprios dados isolados — colaboradores, caixas, escala e configurações pertencem ao fiscal logado. Múltiplos fiscais podem usar o app sem interferência entre si. A política de segurança do banco (Row Level Security) garante o isolamento.

---

## Telas e Funcionalidades

### Autenticação

#### Login
Entrada no app com e-mail e senha via Supabase Auth. Mantém a sessão ativa entre usos.

#### Cadastro
Criação de conta de novo fiscal. O cadastro cria o perfil base que será vinculado a todos os dados do app.

---

### Dashboard
A tela principal do app. Funciona como um painel de controle com:
- **Início de turno** — registra hora de início, lista colaboradores presentes e ausentes, e lança o evento na timeline
- **Acesso rápido** a todos os módulos via cards visuais
- **Resumo do dia** — alertas, quantidade de colaboradores alocados, pendências
- **Navegação inferior** para os módulos mais usados: Mapa, Colaboradores, Escala, Café, Timeline

---

### Mapa de Caixas
Visão geral de todos os caixas em tempo real. Duas abas:

**Aba Mapa** — grade visual com cada caixa e seu status:
- Verde — disponível (sem operador)
- Azul — ocupado (operador trabalhando)
- Vermelho — em manutenção

Ícones e cores diferentes para caixas Self, Rápido e Balcão.

**Aba Caixas** — lista detalhada com filtros por status e tipo.

Ao clicar em um caixa ocupado, abre uma ficha do colaborador com ações rápidas: liberar, marcar intervalo como feito, trocar de caixa.

O mapa também exibe a seção de **Empacotadores** — colaboradores do setor de pacotes escalados no plantão do dia.

> **Saída automática:** quando o horário de saída de um colaborador é atingido, o app libera a alocação automaticamente e registra o evento na timeline.

---

### Alocação
Tela para alocar colaboradores disponíveis nos caixas. Mostra:
- Lista de colaboradores sem caixa atribuído no momento
- Horário previsto de chegada (baseado na escala)
- Opção de selecionar o caixa destino
- Confirmação e registro automático na timeline

---

### Colaboradores
Cadastro e gerenciamento da equipe. Duas abas:

**Aba Lista** — grade responsiva com todos os colaboradores. Em telas maiores (4+ colunas) exibe horário de entrada, status do intervalo e saída diretamente no card, sem precisar abrir o detalhe.

**Aba Status** — visão do turno atual com colaboradores organizados por situação (trabalhando, em intervalo, disponível, folga).

Cada colaborador tem: nome, departamento, cargo, CPF, telefone, histórico de registros de ponto e alocações do dia.

**Departamentos suportados:** Caixa, Fiscal, Pacote, Self, Gerência, Açougue, Padaria, Hortifruti, Depósito, Limpeza, Segurança.

---

### Escala
Planejamento semanal dos turnos. Três níveis:

**Tela principal** — navegação por semana com indicadores de dias preenchidos.

**Dia da semana** — lista de todos os turnos daquele dia, organizados por departamento e ordenados por horário de entrada.

**Formulário de turno** — define entrada, intervalo, retorno e saída de um colaborador. Possui **atalhos de turno** para os horários mais usados:
- 07:40–17:40 (intervalo 12:30–13:30)
- 08:00–18:00 (intervalo 12:00–13:00)
- 09:00–18:00 (intervalo 13:00–14:00)
- 11:20–21:20 (intervalo 14:20–16:20)
- 12:00–21:40 (intervalo 16:00–17:00)
- 14:00–22:00 (intervalo 18:00–18:40)

**Geração automática:** ao clicar em "Gerar Escala da Semana", o app busca o histórico de registros de ponto de cada colaborador e usa o padrão de cada dia da semana como template. Se um colaborador sempre trabalhou às 08:00 nas segundas-feiras, a escala será preenchida com esse horário automaticamente.

---

### Café (Intervalos)
Controle de intervalos durante o turno. Três abas:

**Disponíveis** — colaboradores que ainda não fizeram o intervalo.

**Em Pausa** — colaboradores em intervalo agora.

**Finalizados** — colaboradores que já fizeram o intervalo.

O sistema impede intervalos duplicados e registra cada movimentação na timeline.

---

### Timeline
Log cronológico de tudo que aconteceu no turno. Cada evento registra tipo, colaborador/caixa envolvido, detalhe e horário exato.

A timeline pode ser copiada como texto para compartilhar ou arquivar. É a fonte de verdade do turno.

**Tipos de evento registrados:**
- Turno iniciado / encerrado
- Colaborador alocado / liberado
- Café iniciado / encerrado
- Intervalo iniciado / encerrado
- Empacotador adicionado / removido
- Checklist concluído
- Entrega cadastrada
- Ocorrência registrada
- Anotação criada
- Formulário respondido

---

### Relatório do Dia
Resumo estruturado do turno com estatísticas de alocação, intervalos realizados, ocorrências e entregas. Serve como registro diário da operação.

---

### Entregas
Rastreamento de entregas da loja. Pipeline de status:

1. **Separado** — pedido separado, aguardando saída
2. **Em Rota** — saiu para entrega
3. **Entregue** — confirmado
4. **Cancelado** — pedido cancelado

Filtros por status, cidade e data. O formulário suporta **importação via CSV/texto colado** — basta colar o conteúdo copiado e o app preenche os campos automaticamente.

---

### Ocorrências
Registro de incidentes e problemas durante o turno. Cada ocorrência tem tipo, descrição, nível de gravidade e status (Aberta / Resolvida). Filtro por gravidade e compartilhamento direto.

---

### Procedimentos
Biblioteca de procedimentos operacionais. Categorias:
- **Abertura** — rotinas de início do dia
- **Fechamento** — rotinas de encerramento
- **Emergência** — protocolos de urgência
- **Rotina** — tarefas recorrentes
- **Fiscal** — procedimentos específicos do fiscal
- **Caixa** — procedimentos para operadores

Cada procedimento tem título, descrição e passos numerados. Busca por texto em tempo real.

---

### Checklist
Checklists operacionais com execução rastreada. Fluxo:

1. **Templates** — modelos com itens e cores personalizadas
2. **Execução** — marcar item por item como concluído, com horário de cada marcação
3. **Conclusão** — evento registrado automaticamente na timeline

---

### Formulários
Sistema de formulários customizáveis com campos configuráveis: texto livre, sim/não, número, múltipla escolha.

Três abas: **Templates** (modelos), **Personalizados** (formulários do fiscal) e **Respostas** (histórico de preenchimentos).

---

### Anotações
Bloco de notas do turno com três tipos:
- **Anotação** — nota livre
- **Tarefa** — item a ser feito (pode ser marcado como concluído)
- **Lembrete** — nota com data/hora de alerta

Lembretes vencidos ficam destacados. Filtros por tipo e prioridade.

---

### Passagem de Turno
Registro estruturado para o próximo fiscal com resumo do turno, pendências abertas e recados. Pode ser copiado como texto ou compartilhado diretamente.

---

### Guia Rápido
Base de conhecimento operacional para consulta rápida, organizada por categorias. Busca por texto integrada.

---

### Notificações
Histórico de todas as notificações geradas pelo app durante o turno. Cada ação relevante (alocação, liberação, erro, confirmação) é registrada aqui além de aparecer brevemente no aviso inferior da tela. Notificações não lidas ficam destacadas e podem ser marcadas como lidas individualmente ou todas de uma vez.

---

### Perfil
Edição dos dados do fiscal: nome, telefone, nome da loja e alteração de senha.

### Configurações
Informações gerais do app e dados da loja do fiscal logado.

---

## Estrutura do Projeto

```
lib/
├── main.dart                    # Inicialização, providers, roteamento
├── core/
│   ├── constants/               # Cores, tipografia, dimensões
│   └── utils/                   # Helpers (AppNotif, etc.)
├── domain/
│   ├── entities/                # Modelos de dados
│   ├── enums/                   # Enumerações
│   └── usecases/                # Regras de negócio
├── data/
│   ├── datasources/remote/      # Clientes Supabase
│   ├── models/                  # Conversão JSON ↔ Entity
│   └── repositories/            # Abstração de acesso a dados
└── presentation/
    ├── providers/               # 19 providers de estado
    ├── screens/                 # 52 telas em 24 módulos
    └── widgets/                 # Componentes reutilizáveis
```

---

## Providers

| Provider | Responsabilidade |
|---|---|
| `AuthProvider` | Sessão e autenticação |
| `FiscalProvider` | Dados do fiscal logado |
| `ColaboradorProvider` | Cadastro e status da equipe |
| `CaixaProvider` | Caixas e seus estados |
| `AlocacaoProvider` | Alocações ativas e históricas |
| `EscalaProvider` | Escala semanal de turnos |
| `CafeProvider` | Controle de intervalos |
| `EntregaProvider` | Pipeline de entregas |
| `ProcedimentoProvider` | Biblioteca de procedimentos |
| `NotaProvider` | Anotações e lembretes |
| `FormularioProvider` | Templates e respostas de formulários |
| `OcorrenciaProvider` | Registro de ocorrências |
| `ChecklistProvider` | Checklists e execuções |
| `PassagemTurnoProvider` | Passagens de turno |
| `GuiaRapidoProvider` | Guias de referência rápida |
| `EventoTurnoProvider` | Timeline de eventos |
| `RegistroPontoProvider` | Registros de ponto históricos |
| `PacotePlantaoProvider` | Empacotadores do plantão |
| `NotificacaoProvider` | Histórico de notificações |
