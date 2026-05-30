# Sent Messages Architecture

Sent Messages are the cross-channel audit history for outbound assistant communication.

This feature stores communication the assistant sends or attempts to send, independent from transport.

## Ownership

- Sent Messages do not belong to WhatsAppCrawling because outbound audit history is not WhatsApp-specific.
- Sent Messages do not belong to Sensitive Data or My Data because this is operational action history, not user-owned secret data.
- Channel-specific features own transport behavior; Sent Messages owns only outbound audit records.
- Sent Messages owns outbound assistant identity settings: assistant name, message prefix/postfix, and message header/footer.

## Model

`SentMessage` is a data-only domain model with:

- `id`
- `issueId`
- `targetKind`
- `targetId`
- `targetTitle`
- `messages`
- `status`
- `providerMessageIds`
- `errorMessage`

Do not add repository behavior, merge/upsert behavior, or Firebase audit metadata fields to this model.

## Persistence

`FirestoreSentMessageRepository` extends `FirestoreRepository<SentMessage>` and stores records under the profile-scoped `SentMessages` collection.

Feature-specific queries may filter by `issueId` and by `(targetKind, targetId)`.

## Runtime and integrations

`SentMessagesFeature` owns a non-optional `FirestoreSentMessageRepository` and exposes helper methods for recording outbound attempts.

External send actions should eventually validate `issueId` through `IssuesFeature` before recording and sending.

This feature is transport-agnostic and does not send messages itself.

## Planned integrations

Future integrations include:

- Chats / WhatsApp outbound `send_message`
- Client Voice `speak_to_client`
- Client Voice `ask_to_client`
- future email outbound actions

## Outbound formatting rules

SentMessages settings define how outbound text is composed:

```text
<header>

<prefix><message 1><postfix>
<prefix><message 2><postfix>

<footer>
```

- Include only non-empty values.
- Header is placed before the outbound message batch/body.
- Footer is placed after the outbound message batch/body.
- Prefix/postfix are applied around each individual message text.
- Avoid extra blank lines when header/footer are empty.
- Final formatting behavior should stay centralized in SentMessages.

Future `send_message`, `speak_to_client`, and `ask_to_client` should compose outbound communication through these settings.

## Deferred send transport flow

Real transport send behavior is intentionally deferred. When implemented, `send_message` should:

1. require `issueId`
2. validate the active issue through Issues
3. apply SentMessages outbound identity settings
4. create a SentMessage audit record with `.pending`
5. call channel-specific transport
6. store provider message IDs when available
7. update SentMessage status to `.sent` or `.failed`
8. later reconcile observed source messages as assistant/outgoing
