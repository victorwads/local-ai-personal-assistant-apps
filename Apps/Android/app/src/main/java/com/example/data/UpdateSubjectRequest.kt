package com.example.data

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class UpdateSubjectRequest(
    val status: String,
    val notes: String? = null
)
