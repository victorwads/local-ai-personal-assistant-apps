package com.example.ui

fun formatPunctuation(rawText: String): String {
    return rawText
        .replace(Regex("(?i)\\bperiod\\b"), ".")
        .replace(Regex("(?i)\\bponto final\\b"), ".")
        .replace(Regex("(?i)\\bponto\\b"), ".")
        .replace(Regex("(?i)\\bcomma\\b"), ",")
        .replace(Regex("(?i)\\bvírgula\\b"), ",")
        .replace(Regex("(?i)\\bexclamation mark\\b"), "!")
        .replace(Regex("(?i)\\bexclamation point\\b"), "!")
        .replace(Regex("(?i)\\bponto de exclamação\\b"), "!")
        .replace(Regex("(?i)\\bquestion mark\\b"), "?")
        .replace(Regex("(?i)\\bponto de interrogação\\b"), "?")
        .replace(Regex("\\s+\\."), ".")
        .replace(Regex("\\s+,"), ",")
        .replace(Regex("\\s+!"), "!")
        .replace(Regex("\\s+\\?"), "?")
}
