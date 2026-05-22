package com.example.data

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class VoiceSpeakResponse(
    val responseText: String,
    val speakText: String
)
