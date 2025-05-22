import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config(); // Ensure environment variables are loaded

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // You can add more pool configuration options here if needed
  // e.g., max: 20, idleTimeoutMillis: 30000, connectionTimeoutMillis: 2000
});

export default pool;

// Optional: Add a simple query function for convenience
export const query = async (text: string, params?: any[]) => {
  const start = Date.now();
  const res = await pool.query(text, params);
  const duration = Date.now() - start;
  console.log('executed query', { text, duration, rows: res.rowCount });
  return res;
};
