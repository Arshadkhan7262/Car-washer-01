import mongoose from 'mongoose';
import https from 'https';

const connectDatabase = async () => {
  try {
    if (!process.env.MONGODB_URI) {
      throw new Error('MONGODB_URI is not defined in environment variables');
    }

    // Connection options to handle DNS and network issues
    const connectionOptions = {
      serverSelectionTimeoutMS: 10000, // Timeout after 10s instead of 30s
      socketTimeoutMS: 45000, // Close sockets after 45s of inactivity
      connectTimeoutMS: 10000, // Give up initial connection after 10s
      retryWrites: true,
      retryReads: true,
    };

    console.log('🔄 Attempting to connect to MongoDB...');
    const conn = await mongoose.connect(process.env.MONGODB_URI, connectionOptions);
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`❌ MongoDB connection error: ${error.message}`);
    
    // Provide helpful error messages
    if (error.message.includes('querySrv') || error.message.includes('EREFUSED')) {
      console.error('\n💡 DNS Resolution Error Detected!');
      console.error('   This usually means:');
      console.error('   1. DNS server cannot resolve MongoDB Atlas SRV records');
      console.error('   2. Network connectivity issues');
      console.error('   3. Firewall/proxy blocking DNS queries');
      console.error('\n🔧 Solutions:');
      console.error('   1. Check your internet connection');
      console.error('   2. Try using Google DNS (8.8.8.8) or Cloudflare DNS (1.1.1.1)');
      console.error('   3. Check if your IP is whitelisted in MongoDB Atlas');
      console.error('   4. Try using a standard connection string instead of mongodb+srv://');
      
      // Get and display public IP
      try {
        const publicIP = await getPublicIP();
        console.error(`\n   Your current public IP: ${publicIP}`);
        console.error('   Add this IP to MongoDB Atlas Network Access whitelist');
      } catch (ipError) {
        console.error('\n   Run this command to get your IP:');
        console.error('   (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content');
      }
    }
    
    process.exit(1);
  }
};

// Helper function to get public IP
const getPublicIP = () => {
  return new Promise((resolve, reject) => {
    https.get('https://api.ipify.org', (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => resolve(data.trim()));
    }).on('error', (err) => reject(err));
  });
};

export default connectDatabase;



