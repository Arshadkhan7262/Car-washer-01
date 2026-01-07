import mongoose from 'mongoose';

const connectDatabase = async () => {
  try {
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/6e5cc667-9ca2-482c-8249-fe079e856385',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'database.config.js:4',message:'Attempting MongoDB connection',data:{mongodbUri:process.env.MONGODB_URI?.substring(0,20)+'...'},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'E'})}).catch(()=>{});
    // #endregion
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/6e5cc667-9ca2-482c-8249-fe079e856385',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'database.config.js:6',message:'MongoDB connection successful',data:{host:conn.connection.host},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'E'})}).catch(()=>{});
    // #endregion

    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/6e5cc667-9ca2-482c-8249-fe079e856385',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'database.config.js:9',message:'MongoDB connection failed',data:{error:error.message,code:error.code},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'E'})}).catch(()=>{});
    // #endregion
    console.error(`❌ MongoDB connection error: ${error.message}`);
    process.exit(1);
  }
};

export default connectDatabase;



