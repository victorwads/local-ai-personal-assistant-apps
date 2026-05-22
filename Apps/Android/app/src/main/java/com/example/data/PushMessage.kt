package com.example.data

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class PushMessage(
    val id: String,
    val textToSpeak: String,
    val timestamp: Long
)
