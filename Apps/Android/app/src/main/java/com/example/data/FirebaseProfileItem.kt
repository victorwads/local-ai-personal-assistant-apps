package com.example.data

import java.util.Date

data class FirebaseProfileItem(
    val id: String,
    val displayName: String,
    val isDefault: Boolean,
    val isAutoStart: Boolean,
    val createdAt: Date
) {
    companion object {
        fun fromMap(documentId: String, map: Map<String, Any>): FirebaseProfileItem? {
            val id = FirestoreValueParsers.stringOrNull(map, "id") ?: documentId
            val displayName = FirestoreValueParsers.stringOrNull(map, "displayName") ?: return null
            val isDefault = map["isDefault"] as? Boolean ?: false
            val isAutoStart = map["isAutoStart"] as? Boolean ?: false
            val createdAt = FirestoreValueParsers.timestampOrNull(map, "createdAt") ?: Date()
            return FirebaseProfileItem(
                id = id,
                displayName = displayName,
                isDefault = isDefault,
                isAutoStart = isAutoStart,
                createdAt = createdAt
            )
        }
    }
}
