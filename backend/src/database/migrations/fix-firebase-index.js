/**
 * Migration: Fix firebaseUid + role compound index
 * 
 * Changes sparse index to partial index to properly handle null values
 * This allows multiple users with firebaseUid: null (email-based registration)
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

async function fixIndex() {
  try {
    console.log('🔄 Starting index fix migration...');
    
    // Connect to MongoDB
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Drop the old sparse index
    try {
      await User.collection.dropIndex('firebaseUid_1_role_1');
      console.log('✅ Dropped old sparse index');
    } catch (error) {
      if (error.code === 27) {
        console.log('ℹ️  Old index does not exist, skipping drop');
      } else {
        throw error;
      }
    }

    // Create new partial index
    await User.collection.createIndex(
      { firebaseUid: 1, role: 1 },
      {
        unique: true,
        partialFilterExpression: { firebaseUid: { $exists: true } },
        name: 'firebaseUid_1_role_1'
      }
    );
    console.log('✅ Created new partial index');

    console.log('\n✅ Index fix completed!');
    console.log('   - Old sparse index: Dropped');
    console.log('   - New partial index: Created');
    console.log('\n📝 This allows multiple users with firebaseUid: null');
    console.log('   while still enforcing uniqueness for non-null values');

    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

fixIndex();

