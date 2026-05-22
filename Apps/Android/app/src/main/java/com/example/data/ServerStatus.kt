package com.example.data

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ServerStatus(
    val connected: Boolean,
    val serverTime: Long,
    val whatsappStatus: String,
    val activeProfileName: String,
    val llmStatus: String,
    val activeSubjectsCount: Int,
    val memoriesCount: Int,
    val recentLogs: List<String> = emptyList()
)
