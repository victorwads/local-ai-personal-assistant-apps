package com.example.data

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class MemoryItem(
    val id: String,
    val content: String,
    val timestamp: Long
)
