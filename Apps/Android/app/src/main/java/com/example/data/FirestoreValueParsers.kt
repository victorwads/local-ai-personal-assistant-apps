package com.example.data

import com.google.firebase.Timestamp
import java.util.Date

object FirestoreValueParsers {
    fun timestampOrNull(map: Map<String, Any>, key: String): Date? {
        val value = map[key]
        return when (value) {
            is Timestamp -> value.toDate()
            is Date -> value
            else -> null
        }
    }

    fun stringOrNull(map: Map<String, Any>, key: String): String? = map[key] as? String

    fun intOrDefault(map: Map<String, Any>, key: String, defaultValue: Int = 0): Int {
        val value = map[key]
        return when (value) {
            is Number -> value.toInt()
            else -> defaultValue
        }
    }
}
