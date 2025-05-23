import { readFileSync } from 'fs';
import { join } from 'path';
import pool from './index';

async function setupDatabase() {
  try {
    // Read the SQL schema file
    const schemaPath = join(__dirname, 'schema.sql');
    const schema = readFileSync(schemaPath, 'utf8');

    // Execute the schema
    await pool.query(schema);
    console.log('Database schema created successfully');
  } catch (error) {
    console.error('Error setting up database:', error);
    process.exit(1);
  } finally {
    // Close the pool
    await pool.end();
  }
}

// Run the setup
setupDatabase(); 