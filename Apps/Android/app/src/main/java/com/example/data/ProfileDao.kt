package com.example.data

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface ProfileDao {
    @Query("SELECT * FROM connection_profiles ORDER BY name ASC")
    fun getAllProfilesFlow(): Flow<List<ConnectionProfile>>

    @Query("SELECT * FROM connection_profiles WHERE isActive = 1 LIMIT 1")
    suspend fun getActiveProfile(): ConnectionProfile?

    @Query("SELECT * FROM connection_profiles WHERE isActive = 1 LIMIT 1")
    fun getActiveProfileFlow(): Flow<ConnectionProfile?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProfile(profile: ConnectionProfile): Long

    @Delete
    suspend fun deleteProfile(profile: ConnectionProfile)

    @Query("UPDATE connection_profiles SET isActive = 0")
    suspend fun deactivateAllProfiles()

    @Query("UPDATE connection_profiles SET isActive = 1 WHERE id = :profileId")
    suspend fun activateProfileById(profileId: Int)

    @Transaction
    suspend fun selectActiveProfile(profileId: Int) {
        deactivateAllProfiles()
        activateProfileById(profileId)
    }
}
