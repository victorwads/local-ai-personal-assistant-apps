package com.example.data

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class SendMessageRequest(
    val message: String
)
