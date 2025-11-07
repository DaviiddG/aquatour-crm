import { query } from '../config/db.js';

const baseSelect = `
  SELECT
    id_destino AS id,
    ciudad,
    pais,
    descripcion,
    clima_promedio AS climaPromedio,
    temporada_alta AS temporadaAlta,
    idioma_principal AS idiomaPrincipal,
    moneda,
    precio_base AS precioBase,
    id_proveedor AS idProveedor
  FROM Destino
`;

export const findAllDestinations = async () => {
  const [rows] = await query(`${baseSelect} ORDER BY pais, ciudad`);
  return rows;
};

export const findDestinationById = async (idDestino) => {
  const [rows] = await query(`${baseSelect} WHERE id_destino = ? LIMIT 1`, [idDestino]);
  return rows[0] ?? null;
};

export const createDestination = async (payload) => {
  const ciudad = payload.ciudad;
  const pais = payload.pais;
  const descripcion = payload.descripcion;
  const climaPromedio = payload.climaPromedio || payload.clima_promedio;
  const temporadaAlta = payload.temporadaAlta || payload.temporada_alta;
  const idiomaPrincipal = payload.idiomaPrincipal || payload.idioma_principal;
  const moneda = payload.moneda;
  const precioBase = payload.precioBase || payload.precio_base;
  const idProveedor = payload.idProveedor || payload.id_proveedor;

  if (!ciudad || !pais) {
    const error = new Error('Los campos ciudad y país son obligatorios');
    error.status = 400;
    throw error;
  }

  const [result] = await query(
    `INSERT INTO Destino (ciudad, pais, descripcion, clima_promedio, temporada_alta, idioma_principal, moneda, precio_base, id_proveedor)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [ciudad, pais, descripcion || null, climaPromedio || null, temporadaAlta || null, idiomaPrincipal || null, moneda || null, precioBase || null, idProveedor || null]
  );

  return findDestinationById(result.insertId);
};

export const updateDestination = async (idDestino, payload) => {
  const ciudad = payload.ciudad;
  const pais = payload.pais;
  const descripcion = payload.descripcion;
  const climaPromedio = payload.climaPromedio || payload.clima_promedio;
  const temporadaAlta = payload.temporadaAlta || payload.temporada_alta;
  const idiomaPrincipal = payload.idiomaPrincipal || payload.idioma_principal;
  const moneda = payload.moneda;
  const precioBase = payload.precioBase || payload.precio_base;
  const idProveedor = payload.idProveedor || payload.id_proveedor;

  if (!ciudad || !pais) {
    const error = new Error('Los campos ciudad y país son obligatorios');
    error.status = 400;
    throw error;
  }

  const [result] = await query(
    `UPDATE Destino
     SET ciudad = ?, pais = ?, descripcion = ?, clima_promedio = ?, temporada_alta = ?, idioma_principal = ?, moneda = ?, precio_base = ?, id_proveedor = ?
     WHERE id_destino = ?`,
    [ciudad, pais, descripcion || null, climaPromedio || null, temporadaAlta || null, idiomaPrincipal || null, moneda || null, precioBase || null, idProveedor || null, idDestino]
  );

  if (result.affectedRows === 0) {
    return null;
  }

  return findDestinationById(idDestino);
};

export const deleteDestination = async (idDestino) => {
  const [result] = await query(`DELETE FROM Destino WHERE id_destino = ?`, [idDestino]);
  return result.affectedRows > 0;
};
