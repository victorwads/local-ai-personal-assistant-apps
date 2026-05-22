package com.example.data

import java.util.Date

data class FirebaseMemoryItem(
    val id: String,
    val key: String,
    val content: String,
    val createdAt: Date,
    val updatedAt: Date
) {
    companion object {
        fun fromMap(map: Map<String, Any>): FirebaseMemoryItem? {
            val id = FirestoreValueParsers.stringOrNull(map, "id") ?: return null
            val key = FirestoreValueParsers.stringOrNull(map, "key") ?: FirestoreValueParsers.stringOrNull(map, "title") ?: return null
            val content = FirestoreValueParsers.stringOrNull(map, "content") ?: return null
            val createdAt = FirestoreValueParsers.timestampOrNull(map, "createdAt") ?: Date()
            val updatedAt = FirestoreValueParsers.timestampOrNull(map, "updatedAt") ?: createdAt
            return FirebaseMemoryItem(id = id, key = key, content = content, createdAt = createdAt, updatedAt = updatedAt)
        }
    }
}
