# AssistantMCPServer (Local) — Codex Plugin

Este plugin conecta o Codex ao **AssistantMCPServer local**, que expõe tools via MCP para operar:

- WhatsApp Desktop (ler/enviar, nicknames, acompanhar respostas)
- Voz com o cliente (hands-free: anunciar e perguntar)
- Subjects (assuntos em andamento)
- Memories (memória persistente)

## Requisitos

- WhatsApp Desktop **aberto** (logado).
- Seu **Assistant MCP Server** rodando em `localhost` (HTTP) na rota `/mcp`.
  - Padrão deste plugin: `http://localhost:8080/mcp`.

## Como usar

1. Inicie o Assistant MCP Server.
2. Abra o WhatsApp Desktop.
3. No Codex, habilite o plugin **AssistantMCPServer (Local)** e use as ferramentas expostas pelo MCP server (ex.: `list_chats`, `get_recent_messages`, `send_message`, `speak_to_client`, `ask_to_client`).

## Dicas

- Apelidos (nicknames): para chamar contatos por “mãe”, “namorado”, “Léo”, use `save_nickname(...)` e depois resolva com `list_nicknames()`.
- Skill abrangente: use a skill `assistant` para orquestrar WhatsApp + Gmail + Calendar (follow-ups, agendamentos, convites).
- Catálogo de tools locais: use a skill `assistantmcpserver` para referência rápida de tools (WhatsApp + voz + Subjects/Memories).

## Ajustes

- Se o seu servidor estiver em outra porta (ex.: `8080`), edite `./.mcp.json` e atualize a `url`.
- Se você quiser usar porta `80`, troque a `url` para `http://localhost/mcp`.
