package com.example.data

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class CreateSubjectRequest(
    val title: String,
    val notes: String = "",
    val linkedContactName: String? = null
)
