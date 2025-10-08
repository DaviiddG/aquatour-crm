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
    p.id_destino AS idDestino
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
  const idDestino = payload.idDestino || payload.id_destino || null;

  if (!nombre) {
    const error = new Error('El nombre del paquete es obligatorio');
    error.status = 400;
    throw error;
  }

  const [result] = await query(
    `INSERT INTO Paquete_Turismo (nombre, descripcion, precio_base, duracion_dias, cupo_maximo, servicios_incluidos, id_destino)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [nombre, descripcion, precioBase, duracionDias, cupoMaximo, serviciosIncluidos, idDestino]
  );

  console.log(`✅ Paquete creado con id=${result.insertId}`);
  return findPackageById(result.insertId);
};

export const updatePackage = async (idPaquete, payload) => {
  const nombre = payload.nombre;
  const descripcion = payload.descripcion;
  const precioBase = payload.precioBase || payload.precio_base;
  const duracionDias = payload.duracionDias || payload.duracion_dias;
  const cupoMaximo = payload.cupoMaximo || payload.cupo_maximo;
  const serviciosIncluidos = payload.serviciosIncluidos || payload.servicios_incluidos;
  const idDestino = payload.idDestino || payload.id_destino || null;

  if (!nombre) {
    const error = new Error('El nombre del paquete es obligatorio');
    error.status = 400;
    throw error;
  }

  const [result] = await query(
    `UPDATE Paquete_Turismo
     SET nombre = ?, descripcion = ?, precio_base = ?, duracion_dias = ?, cupo_maximo = ?, servicios_incluidos = ?, id_destino = ?
     WHERE id_paquete = ?`,
    [nombre, descripcion, precioBase, duracionDias, cupoMaximo, serviciosIncluidos, idDestino, idPaquete]
  );

  if (result.affectedRows === 0) {
    return null;
  }

  return findPackageById(idPaquete);
};

export const deletePackage = async (idPaquete) => {
  const [result] = await query(`DELETE FROM Paquete_Turismo WHERE id_paquete = ?`, [idPaquete]);
  return result.affectedRows > 0;
};
