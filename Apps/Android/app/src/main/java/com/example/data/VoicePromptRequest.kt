package com.example.data

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class VoicePromptRequest(
    val speechTranscript: String
)
