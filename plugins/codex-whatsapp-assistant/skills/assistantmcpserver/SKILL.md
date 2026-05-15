---
name: assistantmcpserver
description: Catálogo de ferramentas do AssistantMCPServer local (WhatsApp + voz + Subjects/Memories) e padrões de uso.
---

# AssistantMCPServer (Local MCP)

Use esta skill quando você precisar operar as **tools do MCP Server local** (não apenas WhatsApp).

Ela cobre:

* WhatsApp Desktop (ler/enviar, nicknames, acompanhar resposta)
* Voz com o cliente (`speak_to_client` / `ask_to_client`)
* Subjects (assuntos em andamento)
* Memories (memória persistente)

## Pré-requisitos

- O app **AssistantMCPServer** está rodando.
- O MCP está acessível em `http://localhost:8080/mcp` (ou a URL definida em `plugins/codex-whatsapp-assistant/.mcp.json`).

## Voice (cliente)

- `speak_to_client(text, ...)`: anuncia algo por voz para o cliente.
- `ask_to_client(prompt, ...)`: pergunta algo por voz para o cliente e aguarda resposta (hands-free).

Regras:

- Use `speak_to_client(...)` para anúncios e feedback (“o que chegou”, “o que vou fazer”, “feito”).
- Use `ask_to_client(...)` para coletar dados faltantes e confirmar ações que mudam estado.

## WhatsApp

- `list_chats()`: lista chats disponíveis.
- `list_unread_chats()`: lista chats com mensagens não lidas.
- `get_recent_messages(chatId, limit)`: lê mensagens recentes para contexto.
- `send_message(chatId, text | messages[])`: envia texto único ou lista de mensagens curtas.
- `wait_for_message(chatId?, afterMessageId?)`: aguarda nova mensagem (long-poll) sem polling agressivo.

### Nicknames (apelidos)

- `list_nicknames(chatId?)`: lista apelidos salvos.
- `save_nickname(chatId, nickname, chatName?)`: salva apelido para um chat (ex.: “mãe”, “namorado”, “Léo”).
- `delete_nickname(id)`: remove um apelido salvo.

Padrões:

- Quando o cliente usar termos como “mãe”, “meu namorado”, “Léo”, prefira `list_nicknames()` para resolver `chatId`.
- Se não existir apelido, procure por nome em `list_chats()` e ofereça salvar com `save_nickname(...)`.
- Prefira `send_message(chatId, messages=[...])` com 2–4 mensagens curtas.

## Subjects

Subjects representam “assuntos” operacionais que podem durar dias.

Tools:

- `create_subject(...)`
- `update_subject(...)`
- `finish_subject(...)`
- `list_active_subjects(...)`
- `get_subject(...)`
- `delete_subject(...)`

Padrões:

- Se um subject estiver em WhatsApp, use `wait_for_message(chatId, afterMessageId)` para acompanhar.
- Persista continuidade atualizando o subject com `update_subject(whatsappAfterMessageId=...)`.

## Memories

Memories representam conhecimento persistente útil sobre o cliente.

Tools:

- `create_memory(...)`
- `list_memories(...)`
- `delete_memory(...)`

Regras:

- Não armazene ruído operacional temporário.
- Armazene preferências recorrentes, estilo de comunicação, pessoas importantes, padrões e contexto útil.

