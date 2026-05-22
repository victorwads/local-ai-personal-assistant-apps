package com.example.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "connection_profiles")
data class ConnectionProfile(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val name: String,
    val host: String,
    val port: Int = 8080,
    val apiKey: String = "",
    val isActive: Boolean = false
) {
    val baseUrl: String
        get() = "http://$host:$port"
}
