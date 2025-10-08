import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

async function killConnections() {
  let connection;
  try {
    console.log('🔌 Intentando conectar a la base de datos...');
    
    // Crear una conexión directa sin pool
    connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT ?? 3306),
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
    });

    console.log('✅ Conectado exitosamente');

    // Obtener todas las conexiones activas
    const [processes] = await connection.query(
      `SELECT id, user, host, db, command, time, state 
       FROM INFORMATION_SCHEMA.PROCESSLIST 
       WHERE user = ? AND id != CONNECTION_ID()`,
      [process.env.DB_USER]
    );

    console.log(`\n📊 Conexiones activas encontradas: ${processes.length}`);
    
    if (processes.length === 0) {
      console.log('✨ No hay conexiones para cerrar');
      return;
    }

    // Mostrar las conexiones
    console.log('\n🔍 Detalles de las conexiones:');
    processes.forEach((proc, index) => {
      console.log(`  ${index + 1}. ID: ${proc.id}, DB: ${proc.db}, Estado: ${proc.state}, Tiempo: ${proc.time}s`);
    });

    // Cerrar cada conexión
    console.log('\n🔨 Cerrando conexiones...');
    for (const proc of processes) {
      try {
        await connection.query(`KILL ?`, [proc.id]);
        console.log(`  ✅ Conexión ${proc.id} cerrada`);
      } catch (err) {
        console.log(`  ⚠️  No se pudo cerrar conexión ${proc.id}: ${err.message}`);
      }
    }

    console.log('\n✨ Proceso completado');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('\n💡 Sugerencias:');
    console.error('   1. Espera 5-10 minutos para que las conexiones expiren automáticamente');
    console.error('   2. Verifica que las credenciales en .env sean correctas');
    console.error('   3. Contacta al soporte de Clever Cloud si el problema persiste');
  } finally {
    if (connection) {
      await connection.end();
      console.log('\n🔌 Conexión del script cerrada');
    }
  }
}

killConnections();
