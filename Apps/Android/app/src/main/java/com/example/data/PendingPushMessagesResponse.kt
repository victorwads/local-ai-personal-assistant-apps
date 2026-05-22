package com.example.data

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class PendingPushMessagesResponse(
    val messages: List<PushMessage> = emptyList()
)
