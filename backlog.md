# Backlog (WhatsApp Assistant)

Arquivo em: `/Users/DevData/victorwads/GitRepos/Personal/AssistantMCPServer/backlog.md`

Instrução: antes de qualquer commit relacionado a itens deste backlog, validar que o build está funcionando usando `scripts/check_build_and_restart.sh`.

Este arquivo reúne ideias e melhorias para retomarmos depois. Cada item fica separado por uma linha `---`.

---

## 1) Encontrar chat que não aparece na lista inicial

**Descrição**  
Quando a conversa não estiver visível na lista principal do app, o agente deve conseguir pesquisar o nome ou número na barra de busca do WhatsApp Web/Desktop, validar o resultado e abrir o chat certo antes de seguir com a ação.

**Por que isso entra no backlog**  
É um fluxo mais complexo e frágil, porque depende de busca, seleção de resultado, validação de ambiguidade e sincronização do contexto do chat antes do envio.

---

## 2) Arquivar conversa

**Descrição**  
Adicionar a capacidade de arquivar uma conversa específica para manter o conjunto de chats ativos mais enxuto e organizado. O comportamento padrão do WhatsApp de reabrir o chat quando chegam mensagens novas continua valendo.

**Evidências/seletores observados na row**  
- `data-testid="list-item-0"` identifica a linha da conversa.
- `data-testid="cell-frame-container"`, `data-testid="cell-frame-title"` e `data-testid="cell-frame-primary-detail"` organizam a estrutura visual da row.
- `data-testid="last-msg-status"` expõe o preview/status da última mensagem.
- `data-testid="status-dblcheck"` indica o estado de entrega/leitura do último envio.
- `aria-label="Conversa fixada"` mostra que há ao menos um estado de pin visível nessa row.
- Neste trecho específico ainda não apareceu o menu ou botão de arquivar; isso precisa ser encontrado em outro nível da UI ou em outro estado do DOM.

**Por que isso entra no backlog**  
É uma melhoria útil para controle de contexto e limpeza da lista de conversas, com uma implementação relativamente direta em comparação com o fluxo de busca/resolução de chat.

---

## 3) Bloqueio e desbloqueio da WebView

**Descrição**  
Adicionar um ícone de bloqueio/desbloqueio ao lado do título do WhatsApp para controlar a interação com a WebView. No modo bloqueado, a WebView fica travada para o usuário, com viewport fixo em `1080p` e mantendo `80%` de escala. No modo desbloqueado, a WebView volta a usar o tamanho disponível da janela, também com `80%` de escala.

**Comportamento desejado**  
- Mostrar um ícone de bloqueado/desbloqueado ao lado do título.
- Quando bloqueado, impedir interação do usuário com a WebView.
- Quando desbloqueado, permitir interação normal e ajustar o viewport ao tamanho da janela.
- Exibir um helper/tooltip avisando que ao desbloquear o pooling de mensagens vai parar.

**Por que isso entra no backlog**  
Isso controla melhor o modo de uso entre automação e interação manual, além de recuperar um comportamento que já existia na primeira versão.

---

## 4) Configuração de seletores via YAML com auto-update

**Descrição**  
Externalizar os seletores e IDs usados no parse do WhatsApp Web para um arquivo `YAML` versionado. Esse arquivo deve ser bundlado no app como padrão, mas o runtime pode baixar uma versão mais recente via uma URL configurável nas Settings. Se a URL estiver vazia, o app usa apenas o `YAML` embutido e não tenta atualizar.

**Regras desejadas**  
- O `YAML` precisa carregar metadados como data da versão e versão do schema.
- Enquanto a versão do schema for compatível, o app pode atualizar só o `YAML` sem exigir atualização do binário.
- Se o schema mudar, a atualização precisa ser feita no app nativo.
- Toda a lógica de parsing atual do WhatsApp Web deve deixar de depender de IDs hardcoded espalhados no código e passar a consultar essa configuração centralizada.
- O `YAML` deve permitir múltiplas alternativas por seletor, para cobrir mudanças de DOM/HTML sem quebrar o fluxo.

**Por que isso entra no backlog**  
Isso reduz o acoplamento com o HTML atual do WhatsApp Web e facilita manter o app funcionando quando a interface mudar, sem precisar lançar uma nova versão para toda alteração pequena de seletor.

---

## 5) `lastMessageAt` estruturado e ordenação por última mensagem

**Descrição**  
Investigar onde o WhatsApp Web expõe a data/hora real da última mensagem em formato estruturado, em vez de depender apenas de texto legível como `quinta-feira` ou `14:50`. O objetivo é mapear esse valor para algo ordenável, preferencialmente `ISO string`, e usar isso tanto na listagem visual quanto no repositório/ordenação interna.

**Contexto observado**  
- No exemplo atual, a row expõe `lastMessageAtText`, `lastMessageDirection`, `lastMessagePreview` e `lastMessageStatus`, mas não mostra um timestamp estruturado.
- O texto exibido pode servir para UI, mas não é confiável para ordenação consistente.
- Se o HTML ou metadado interno trouxer um timestamp em `ISO`, esse campo deve ser o candidato principal para armazenar e ordenar.

**Por que isso entra no backlog**  
Isso melhora a ordenação dos chats e evita depender de texto humano para decidir recência. Como `ISO string` ordena bem lexicograficamente, ela também simplifica a lógica de sorting.

---

## 6) Exposição externa para app mobile e controle por API

**Descrição**  
Externalizar parte da experiência do assistente para uma aplicação mobile ou outra interface cliente, permitindo que o usuário controle a máquina que roda o MCP server e o assistente de forma remota. A ideia é que tanto o fluxo de falar com o cliente quanto o fluxo do cliente responder possam ser acessados por essa camada externa.

**Capacidades desejadas**  
- Expor uma API para integração com app mobile ou outro cliente externo.
- Permitir iniciar, acompanhar e controlar interações sem depender só da máquina local.
- Suportar envio e recebimento de áudio, incluindo gravação e reprodução no dispositivo remoto quando fizer sentido.
- Permitir reconhecimento de voz no lado do cliente, com possibilidade de usar recursos nativos do iPhone/Android ou um backend como `Whisper`.
- Manter a máquina principal como origem do contexto, mas com interface externa para operação e resposta.

**Por que isso entra no backlog**  
Isso amplia o alcance do assistente para fora da máquina local e abre caminho para uma experiência mais portátil, principalmente para controlar conversas e áudios pelo celular.

---

## 7) Corrigir ordenação e metadados da lista de chats

**Descrição**  
Corrigir o bug em que a listagem de chats fica desordenada quando o WhatsApp Web retorna apenas textos como `quinta-feira` ou horários soltos em vez de uma data completa da última mensagem. Hoje, a integração parece não expor um timestamp estruturado no HTML, então a ordenação por idade fica inconsistente e não confiável.

**Problema observado**  
- Em `list chats`, o campo da última mensagem às vezes aparece só como texto humano, sem `ISO date`.
- Quando a última mensagem não traz data completa, a ordenação quebra ou fica parcial.
- Alguns metadados da última mensagem ainda precisam ser recuperados corretamente, incluindo o status da última mensagem.
- A versão nativa já parecia tratar melhor esses dados, mas no Web isso ainda não está estável.

**Objetivo**  
- Encontrar a origem correta da data da última mensagem, se ela existir em algum metadado interno do WhatsApp Web.
- Usar essa data estruturada para ordenar os chats no repositório e na listagem visual.
- Garantir que o status da última mensagem também seja preenchido corretamente.

**Por que isso entra no backlog**  
Sem uma data real e estruturada, a lista não consegue ser ordenada por recência com confiança, o que afeta diretamente a experiência e a leitura operacional dos chats.

---

## 8) `wait for event` não pode consumir pendências

**Descrição**  
Corrigir o bug em que o `wait for event` está marcando como resolvidas ou “handled” conversas que ainda não tiveram suas mensagens lidas pelo fluxo correto. Hoje ele lista chats com conversa pendente, mas se for chamado de novo sem passar por `list recent messages`, ele já zera o estado e faz o sistema perder pendências.

**Regra desejada**  
- `wait for event` apenas informa quais chats têm pendência.
- Somente `list recent messages` pode marcar mensagens como `handled` para um chat específico.
- Se `list recent messages` não for chamado, o mesmo chat precisa continuar aparecendo como pendente no próximo `wait for event`.
- A limpeza de lido/handled deve ocorrer apenas depois do pull real das mensagens do chat.
- A resposta do `wait for event` precisa trazer o nome do evento, como `prompt_from_cliente` ou `unhandled_chat`, e não apenas um tipo genérico como `chat_messages`.
- O payload do evento deve ser explícito o suficiente para distinguir o que aconteceu sem depender de inferência externa.

**Por que isso entra no backlog**  
Esse bug quebra o fluxo de consumo do assistente e faz perder mensagens antes da leitura real, então a responsabilidade de “consumir” precisa ficar restrita ao endpoint certo.

---

Exemplo de prompts finais:
- Execute as alterações do item `## X) Xxxxx Xxx Xxxxx Xxxxx` do arquivo `backlog.md`.
- Pode remover do backlog e comitar as alterações e o backlog inteiro. (após permissão explicita para remover do backlog)
