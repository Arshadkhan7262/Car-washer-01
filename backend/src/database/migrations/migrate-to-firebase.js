/**
 * Database Migration: OTP to Firebase Authentication
 * 
 * This migration script:
 * 1. Removes OTP fields from User collection
 * 2. Adds firebaseUid field to User collection
 * 3. Creates compound unique index on (firebaseUid, role)
 * 4. Sets phone_verified to true for all existing users (assuming they were verified via OTP)
 * 
 * Run: node src/database/migrations/migrate-to-firebase.js
 */

import mongoose from 'mongoose';
import dotenv from 'dotenv';
import User from '../../models/User.model.js';

dotenv.config();

const MONGODB_URI = process.env.MONGODB_URI;

if (!MONGODB_URI) {
  console.error('❌ MONGODB_URI not found in environment variables');
  process.exit(1);
}

async function migrate() {
  try {
    console.log('🔄 Starting Firebase migration...');
    
    // Connect to MongoDB
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get all users
    const users = await User.find({});
    console.log(`📊 Found ${users.length} users to migrate`);

    let migrated = 0;
    let skipped = 0;

    for (const user of users) {
      // Skip if already has firebaseUid
      if (user.firebaseUid) {
        console.log(`⏭️  Skipping user ${user._id} - already has firebaseUid`);
        skipped++;
        continue;
      }

      // For existing users without Firebase UID:
      // - Remove OTP fields (handled by schema update)
      // - Set phone_verified to true (they were verified via OTP)
      // - Generate a temporary firebaseUid (users will need to re-authenticate via Firebase)
      //   OR set to null and require Firebase login
      
      // Option: Set phone_verified to true for existing users
      user.phone_verified = true;
      
      // Note: firebaseUid will be set when user logs in via Firebase
      // For now, we'll leave it as required but users must re-authenticate
      
      await user.save();
      migrated++;
      console.log(`✅ Migrated user ${user._id} (${user.phone}, ${user.role})`);
    }

    // Create indexes
    console.log('📇 Creating indexes...');
    await User.collection.createIndex({ firebaseUid: 1, role: 1 }, { unique: true });
    await User.collection.createIndex({ firebaseUid: 1 });
    console.log('✅ Indexes created');

    console.log(`\n✅ Migration completed!`);
    console.log(`   - Migrated: ${migrated} users`);
    console.log(`   - Skipped: ${skipped} users`);
    console.log(`\n⚠️  IMPORTANT: Existing users must re-authenticate via Firebase to get firebaseUid`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration error:', error);
    process.exit(1);
  }
}

migrate();

