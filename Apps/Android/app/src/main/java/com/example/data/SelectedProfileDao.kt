package com.example.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface SelectedProfileDao {
    @Query("SELECT * FROM selected_profile_state WHERE id = 0 LIMIT 1")
    fun getSelectedProfileFlow(): Flow<SelectedProfileEntity?>

    @Query("SELECT * FROM selected_profile_state WHERE id = 0 LIMIT 1")
    suspend fun getSelectedProfile(): SelectedProfileEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertSelectedProfile(state: SelectedProfileEntity)
}
