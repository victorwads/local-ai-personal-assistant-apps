package com.example.data

import java.util.Date

data class FirebaseVoiceEventItem(
    val id: String,
    val kind: String,
    val prompt: String?,
    val text: String?,
    val transcript: String?,
    val draftTranscript: String?,
    val askStatus: String?,
    val createdAt: Date,
    val answeredAt: Date?
) {
    companion object {
        fun fromMap(map: Map<String, Any>): FirebaseVoiceEventItem? {
            val id = FirestoreValueParsers.stringOrNull(map, "id") ?: return null
            val kind = FirestoreValueParsers.stringOrNull(map, "kind") ?: return null
            val prompt = FirestoreValueParsers.stringOrNull(map, "prompt")
            val text = FirestoreValueParsers.stringOrNull(map, "text")
            val transcript = FirestoreValueParsers.stringOrNull(map, "transcript")
            val draftTranscript = FirestoreValueParsers.stringOrNull(map, "draftTranscript")
            val askStatus = FirestoreValueParsers.stringOrNull(map, "askStatus")
            val createdAt = FirestoreValueParsers.timestampOrNull(map, "createdAt") ?: Date()
            val answeredAt = FirestoreValueParsers.timestampOrNull(map, "answeredAt")
            return FirebaseVoiceEventItem(
                id = id,
                kind = kind,
                prompt = prompt,
                text = text,
                transcript = transcript,
                draftTranscript = draftTranscript,
                askStatus = askStatus,
                createdAt = createdAt,
                answeredAt = answeredAt
            )
        }
    }
}
