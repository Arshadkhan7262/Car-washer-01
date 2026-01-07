import mongoose from 'mongoose';
import dotenv from 'dotenv';
import connectDatabase from '../../config/database.config.js';

// Load environment variables
dotenv.config();

/**
 * Migration: Fix phone uniqueness index
 * Changes from unique phone to compound unique (phone, role)
 */
const fixPhoneIndex = async () => {
  try {
    console.log('🔄 Starting phone index migration...');
    
    // Connect to database
    await connectDatabase();
    
    const db = mongoose.connection.db;
    const collection = db.collection('users');
    
    // Get all indexes
    const indexes = await collection.indexes();
    console.log('📋 Current indexes:', indexes.map(idx => idx.name));
    
    // Check if old phone_1 index exists
    const phoneIndex = indexes.find(idx => idx.name === 'phone_1');
    
    if (phoneIndex) {
      console.log('🗑️  Dropping old phone_1 index...');
      try {
        await collection.dropIndex('phone_1');
        console.log('✅ Old index dropped');
      } catch (error) {
        if (error.codeName === 'IndexNotFound') {
          console.log('ℹ️  Index already dropped');
        } else {
          throw error;
        }
      }
    }
    
    // Check if compound index exists
    const compoundIndex = indexes.find(idx => 
      idx.key && idx.key.phone === 1 && idx.key.role === 1
    );
    
    if (!compoundIndex) {
      console.log('➕ Creating compound unique index (phone, role)...');
      await collection.createIndex(
        { phone: 1, role: 1 },
        { unique: true, name: 'phone_1_role_1' }
      );
      console.log('✅ Compound index created');
    } else {
      console.log('ℹ️  Compound index already exists');
    }
    
    // Verify
    const newIndexes = await collection.indexes();
    console.log('📋 Updated indexes:', newIndexes.map(idx => idx.name));
    
    console.log('✅ Migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
};

// Run migration
fixPhoneIndex();

