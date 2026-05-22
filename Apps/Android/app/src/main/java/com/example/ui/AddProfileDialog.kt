package com.example.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog

@Composable
fun AddProfileDialog(onDismiss: () -> Unit, onAdd: (String, String, Int, String) -> Unit) {
    var name by remember { mutableStateOf("") }
    var host by remember { mutableStateOf("10.0.2.2") }
    var portString by remember { mutableStateOf("8080") }
    var apiKey by remember { mutableStateOf("") }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            colors = CardDefaults.cardColors(containerColor = UiTokens.CardOverlayBg),
            border = UiTokens.borderStroke(),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text("Register Mac Server Profile", fontWeight = FontWeight.Bold, color = UiTokens.TextDark, fontSize = 16.sp)
                Spacer(modifier = Modifier.height(12.dp))
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    placeholder = { Text("Profile Name (e.g. Living room Mac)", color = UiTokens.MutedSlate) },
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = UiTokens.PrimaryEmerald,
                        unfocusedBorderColor = UiTokens.BorderColor,
                        focusedTextColor = UiTokens.TextDark,
                        unfocusedTextColor = UiTokens.TextDark
                    ),
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(modifier = Modifier.fillMaxWidth()) {
                    OutlinedTextField(
                        value = host,
                        onValueChange = { host = it },
                        placeholder = { Text("Server Host IP", color = UiTokens.MutedSlate) },
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = UiTokens.PrimaryEmerald,
                            unfocusedBorderColor = UiTokens.BorderColor,
                            focusedTextColor = UiTokens.TextDark,
                            unfocusedTextColor = UiTokens.TextDark
                        ),
                        modifier = Modifier.weight(1.8f)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    OutlinedTextField(
                        value = portString,
                        onValueChange = { portString = it },
                        placeholder = { Text("Port", color = UiTokens.MutedSlate) },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = UiTokens.PrimaryEmerald,
                            unfocusedBorderColor = UiTokens.BorderColor,
                            focusedTextColor = UiTokens.TextDark,
                            unfocusedTextColor = UiTokens.TextDark
                        ),
                        modifier = Modifier.weight(1f)
                    )
                }
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = apiKey,
                    onValueChange = { apiKey = it },
                    placeholder = { Text("API Secret Key / Bearer (Optional)", color = UiTokens.MutedSlate) },
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = UiTokens.PrimaryEmerald,
                        unfocusedBorderColor = UiTokens.BorderColor,
                        focusedTextColor = UiTokens.TextDark,
                        unfocusedTextColor = UiTokens.TextDark
                    ),
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(16.dp))
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                    TextButton(onClick = onDismiss, colors = ButtonDefaults.textButtonColors(contentColor = UiTokens.PrimaryEmerald)) {
                        Text("Cancel")
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Button(
                        onClick = {
                            if (name.isNotBlank() && host.isNotBlank()) {
                                val port = portString.toIntOrNull() ?: 8080
                                onAdd(name, host, port, apiKey)
                            }
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = UiTokens.PrimaryEmerald, contentColor = Color.White)
                    ) {
                        Text("Save Profile")
                    }
                }
            }
        }
    }
}
