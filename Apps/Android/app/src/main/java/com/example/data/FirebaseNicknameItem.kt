package com.example.data

import java.util.Date

data class FirebaseNicknameItem(
    val id: String,
    val originalName: String,
    val nickname: String,
    val chatId: String?,
    val createdAt: Date
) {
    companion object {
        fun fromMap(map: Map<String, Any>): FirebaseNicknameItem? {
            val id = FirestoreValueParsers.stringOrNull(map, "id") ?: return null
            val originalName = FirestoreValueParsers.stringOrNull(map, "originalName") ?: FirestoreValueParsers.stringOrNull(map, "chatName") ?: return null
            val nickname = FirestoreValueParsers.stringOrNull(map, "nickname") ?: return null
            val chatId = FirestoreValueParsers.stringOrNull(map, "chatId")
            val createdAt = FirestoreValueParsers.timestampOrNull(map, "createdAt") ?: Date()
            return FirebaseNicknameItem(
                id = id,
                originalName = originalName,
                nickname = nickname,
                chatId = chatId,
                createdAt = createdAt
            )
        }
    }
}
