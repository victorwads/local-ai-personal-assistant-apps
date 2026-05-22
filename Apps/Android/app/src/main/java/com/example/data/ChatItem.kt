package com.example.data

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ChatItem(
    val id: String,
    val name: String,
    val unreadCount: Int = 0,
    val lastMessage: String = "",
    val timestamp: Long = System.currentTimeMillis()
)
