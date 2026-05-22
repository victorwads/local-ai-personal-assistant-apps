package com.example.data

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class VoiceRequestItem(
    val id: String,
    val kind: String,
    val title: String,
    val body: String,
    val status: String,
    val createdAt: Long,
    val handledAt: Long? = null,
    val responseText: String? = null
)
