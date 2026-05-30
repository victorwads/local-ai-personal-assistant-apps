# Sent Messages Architecture

Sent Messages are the cross-channel audit history for outbound assistant communication.

This feature stores communication the assistant sends or attempts to send, independent from transport.

## Ownership

- Sent Messages do not belong to WhatsAppCrawling because outbound audit history is not WhatsApp-specific.
- Sent Messages do not belong to Sensitive Data or My Data because this is operational action history, not user-owned secret data.
- Channel-specific features own transport behavior; Sent Messages owns only outbound audit records.

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
