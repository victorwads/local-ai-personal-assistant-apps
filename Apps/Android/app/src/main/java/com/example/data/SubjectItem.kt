package com.example.data

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class SubjectItem(
    val id: String,
    val title: String,
    val notes: String = "",
    val status: String,
    val creationTime: Long,
    val linkedContactName: String? = null
)
