import { query } from '../config/db.js';

const baseSelect = `
  SELECT
    p.id_paquete AS id,
    p.nombre,
    p.descripcion,
    p.precio_base AS precioBase,
    p.duracion_dias AS duracionDias,
    p.cupo_maximo AS cupoMaximo,
    p.servicios_incluidos AS serviciosIncluidos,
    p.destinos_ids
  FROM Paquete_Turismo p
`;

export const findAllPackages = async () => {
  const [rows] = await query(`${baseSelect} ORDER BY p.nombre ASC`);
  console.log(`📦 Paquetes encontrados: ${rows.length}`);
  return rows;
};

export const findPackageById = async (idPaquete) => {
  const [rows] = await query(`${baseSelect} WHERE p.id_paquete = ? LIMIT 1`, [idPaquete]);
  return rows[0] ?? null;
};

export const createPackage = async (payload) => {
  console.log('📦 Payload de paquete recibido:', JSON.stringify(payload, null, 2));
  
  const nombre = payload.nombre;
  const descripcion = payload.descripcion;
  const precioBase = payload.precioBase || payload.precio_base || 0;
  const duracionDias = payload.duracionDias || payload.duracion_dias || 1;
  const cupoMaximo = payload.cupoMaximo || payload.cupo_maximo || 1;
  const serviciosIncluidos = payload.serviciosIncluidos || payload.servicios_incluidos;
  const destinosIds = payload.destinos_ids || payload.destinosIds || null;

  console.log('📦 Destinos a guardar:', destinosIds);

  if (!nombre) {
    const error = new Error('El nombre del paquete es obligatorio');
    error.status = 400;
    throw error;
  }

  const [result] = await query(
    `INSERT INTO Paquete_Turismo (nombre, descripcion, precio_base, duracion_dias, cupo_maximo, servicios_incluidos, destinos_ids)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [nombre, descripcion, precioBase, duracionDias, cupoMaximo, serviciosIncluidos, destinosIds]
  );

  console.log(`✅ Paquete creado con id=${result.insertId}, destinos=${destinosIds}`);
  return findPackageById(result.insertId);
};

export const updatePackage = async (idPaquete, payload) => {
  const nombre = payload.nombre;
  const descripcion = payload.descripcion;
  const precioBase = payload.precioBase || payload.precio_base;
  const duracionDias = payload.duracionDias || payload.duracion_dias;
  const cupoMaximo = payload.cupoMaximo || payload.cupo_maximo;
  const serviciosIncluidos = payload.serviciosIncluidos || payload.servicios_incluidos;
  const destinosIds = payload.destinos_ids || payload.destinosIds || null;

  console.log('📦 Actualizando paquete', idPaquete, 'con destinos:', destinosIds);

  if (!nombre) {
    const error = new Error('El nombre del paquete es obligatorio');
    error.status = 400;
    throw error;
  }

  const [result] = await query(
    `UPDATE Paquete_Turismo
     SET nombre = ?, descripcion = ?, precio_base = ?, duracion_dias = ?, cupo_maximo = ?, servicios_incluidos = ?, destinos_ids = ?
     WHERE id_paquete = ?`,
    [nombre, descripcion, precioBase, duracionDias, cupoMaximo, serviciosIncluidos, destinosIds, idPaquete]
  );

  if (result.affectedRows === 0) {
    return null;
  }

  console.log(`✅ Paquete ${idPaquete} actualizado con destinos=${destinosIds}`);
  return findPackageById(idPaquete);
};

export const deletePackage = async (idPaquete) => {
  try {
    // Verificar si hay reservas asociadas a este paquete
    const [reservas] = await query(
      `SELECT COUNT(*) as count FROM Reserva WHERE id_paquete = ?`,
      [idPaquete]
    );
    
    if (reservas[0].count > 0) {
      const error = new Error(`No se puede eliminar el paquete porque tiene ${reservas[0].count} reserva(s) asociada(s). Elimina primero las reservas.`);
      error.status = 409; // Conflict
      throw error;
    }
    
    // Verificar si hay cotizaciones asociadas a este paquete
    const [cotizaciones] = await query(
      `SELECT COUNT(*) as count FROM Cotizacion WHERE id_paquete = ?`,
      [idPaquete]
    );
    
    if (cotizaciones[0].count > 0) {
      const error = new Error(`No se puede eliminar el paquete porque tiene ${cotizaciones[0].count} cotización(es) asociada(s). Elimina primero las cotizaciones.`);
      error.status = 409; // Conflict
      throw error;
    }
    
    // Si no hay dependencias, eliminar el paquete
    const [result] = await query(`DELETE FROM Paquete_Turismo WHERE id_paquete = ?`, [idPaquete]);
    
    if (result.affectedRows === 0) {
      const error = new Error('Paquete no encontrado');
      error.status = 404;
      throw error;
    }
    
    console.log(`✅ Paquete ${idPaquete} eliminado exitosamente`);
    return true;
  } catch (error) {
    console.error(`❌ Error eliminando paquete ${idPaquete}:`, error.message);
    throw error;
  }
};
