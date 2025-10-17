import { getConnection } from './src/config/db.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function runMigration() {
  const connection = await getConnection();
  
  try {
    console.log('📋 Ejecutando migración: add_activo_column.sql');
    
    const migrationPath = path.join(__dirname, 'migrations', 'add_activo_column.sql');
    const sql = fs.readFileSync(migrationPath, 'utf8');
    
    // Dividir por punto y coma para ejecutar cada statement por separado
    const statements = sql
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));
    
    for (const statement of statements) {
      console.log(`Ejecutando: ${statement.substring(0, 50)}...`);
      await connection.execute(statement);
    }
    
    console.log('✅ Migración ejecutada exitosamente');
  } catch (error) {
    console.error('❌ Error ejecutando migración:', error.message);
    throw error;
  } finally {
    connection.release();
    process.exit(0);
  }
}

runMigration();
