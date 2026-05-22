package com.example.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "selected_profile_state")
data class SelectedProfileEntity(
    @PrimaryKey val id: Int = 0,
    val selectedProfileId: String? = null
)
