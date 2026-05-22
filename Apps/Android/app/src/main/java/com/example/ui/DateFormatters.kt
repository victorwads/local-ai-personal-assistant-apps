package com.example.ui

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object DateFormatters {
    fun shortDateTime(date: Date): String = SimpleDateFormat("dd MMM yyyy HH:mm", Locale.getDefault()).format(date)
    fun shortTime(date: Date): String = SimpleDateFormat("dd MMM HH:mm", Locale.getDefault()).format(date)
}
