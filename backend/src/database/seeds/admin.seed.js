import mongoose from 'mongoose';
import dotenv from 'dotenv';
import AdminUser from '../../models/AdminUser.model.js';
import connectDatabase from '../../config/database.config.js';

// Load environment variables
dotenv.config();

const seedSuperAdmin = async () => {
  try {
    // Connect to database
    await connectDatabase();

    const adminEmail = process.env.ADMIN_EMAIL || 'admin@carwashpro.com';
    const adminPassword = process.env.ADMIN_PASSWORD || 'Admin@123';
    const adminName = process.env.ADMIN_NAME || 'Super Admin';

    // Check if super admin already exists
    const existingAdmin = await AdminUser.findOne({ email: adminEmail });

    if (existingAdmin) {
      console.log('⚠️  Super admin already exists with email:', adminEmail);
      process.exit(0);
    }

    // Create super admin
    const superAdmin = await AdminUser.create({
      name: adminName,
      email: adminEmail,
      password: adminPassword,
      role: 'super_admin',
      is_active: true
    });

    console.log('✅ Super admin created successfully!');
    console.log('📧 Email:', superAdmin.email);
    console.log('👤 Name:', superAdmin.name);
    console.log('🔑 Role:', superAdmin.role);
    console.log('💡 Default password:', adminPassword);
    console.log('⚠️  Please change the password after first login!');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding super admin:', error.message);
    process.exit(1);
  }
};

// Run seed
seedSuperAdmin();








