package com.example.data

import java.util.Date

data class FirebaseSubjectItem(
    val id: String,
    val title: String,
    val summary: String,
    val status: String,
    val priority: Int,
    val createdAt: Date,
    val updatedAt: Date
) {
    companion object {
        fun fromMap(map: Map<String, Any>): FirebaseSubjectItem? {
            val id = FirestoreValueParsers.stringOrNull(map, "id") ?: return null
            val title = FirestoreValueParsers.stringOrNull(map, "title") ?: return null
            val summary = FirestoreValueParsers.stringOrNull(map, "summary") ?: FirestoreValueParsers.stringOrNull(map, "details") ?: ""
            val status = FirestoreValueParsers.stringOrNull(map, "status") ?: "active"
            val priority = FirestoreValueParsers.intOrDefault(map, "priority", 0)
            val createdAt = FirestoreValueParsers.timestampOrNull(map, "createdAt") ?: Date()
            val updatedAt = FirestoreValueParsers.timestampOrNull(map, "updatedAt") ?: createdAt
            return FirebaseSubjectItem(
                id = id,
                title = title,
                summary = summary,
                status = status,
                priority = priority,
                createdAt = createdAt,
                updatedAt = updatedAt
            )
        }
    }
}
