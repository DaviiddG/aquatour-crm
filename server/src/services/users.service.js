import { query, getConnection } from '../config/db.js';
import { hashPassword } from './password.service.js';

const roleDbToApp = {
  Superadministrador: 'superadministrador',
  Administrador: 'administrador',
  Asesor: 'empleado',
  Cliente: 'empleado',
};

const roleAppToDb = {
  superadministrador: 'Superadministrador',
  administrador: 'Administrador',
  empleado: 'Asesor',
};

const docDbToApp = {
  'Cedula Ciudadania': 'CC',
  'Tarjeta Identidad': 'TI',
  'Pasaporte': 'PP',
  'Documento Extranjeria': 'CE',
  'NIT': 'NIT',
};

const docAppToDb = Object.fromEntries(Object.entries(docDbToApp).map(([db, app]) => [app, db]));

const genderDbToApp = {
  M: 'Masculino',
  F: 'Femenino',
  Otro: 'Otro',
};

const genderAppToDb = {
  Masculino: 'M',
  Femenino: 'F',
  Otro: 'Otro',
};

const baseSelect = `
  SELECT
    u.id_usuario,
    u.nombre,
    u.apellido,
    u.correo AS email,
    COALESCE(r.rol, 'Asesor') AS rol_db,
    u.tipo_documento,
    u.num_documento,
    u.fecha_nacimiento,
    u.genero,
    u.telefono,
    u.direccion,
    u.ciudad_residencia,
    u.pais_residencia,
    u.contrasena,
    u.fecha_registro AS created_at,
    u.fecha_registro AS updated_at
  FROM Usuario u
  LEFT JOIN Rol r ON u.id_rol = r.id_rol
`;

const mapDbUser = (row) => {
  if (!row) return null;

  return {
    id_usuario: row.id_usuario,
    nombre: row.nombre,
    apellido: row.apellido,
    email: row.email,
    rol: roleDbToApp[row.rol_db] ?? 'empleado',
    tipo_documento: docDbToApp[row.tipo_documento] ?? row.tipo_documento,
    num_documento: row.num_documento,
    fecha_nacimiento: row.fecha_nacimiento,
    genero: genderDbToApp[row.genero] ?? row.genero,
    telefono: row.telefono ? row.telefono.toString() : '',
    direccion: row.direccion,
    ciudad_residencia: row.ciudad_residencia,
    pais_residencia: row.pais_residencia,
    contrasena: row.contrasena,
    activo: true,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
};

const resolveRoleId = async (roleApp) => {
  const roleDb = roleAppToDb[roleApp] ?? 'Asesor';
  const [rows] = await query(
    'SELECT id_rol FROM Rol WHERE rol = ? LIMIT 1',
    [roleDb]
  );
  return rows[0]?.id_rol ?? null;
};

export const findByEmail = async (email, excludeId) => {
  const params = [email];
  let whereClause = 'u.correo = ?';

  if (excludeId) {
    whereClause += ' AND u.id_usuario <> ?';
    params.push(excludeId);
  }

  const [rows] = await query(
    `${baseSelect}
     WHERE ${whereClause}
     LIMIT 1`,
    params
  );
  return mapDbUser(rows[0]) ?? null;
};

export const findAllUsers = async () => {
  const [rows] = await query(`${baseSelect} ORDER BY u.fecha_registro DESC`);
  return rows.map((row) => {
    const user = mapDbUser(row);
    if (user) delete user.contrasena;
    return user;
  });
};

export const findUserById = async (idUsuario) => {
  const [rows] = await query(
    `${baseSelect}
     WHERE u.id_usuario = ?
     LIMIT 1`,
    [idUsuario]
  );
  const user = mapDbUser(rows[0]);
  if (user) delete user.contrasena;
  return user;
};

const mapAppUserToDbFields = async (userData) => {
  const roleId = await resolveRoleId(userData.rol ?? 'empleado');
  const tipoDocumentoDb = docAppToDb[userData.tipo_documento ?? 'CC'] ?? userData.tipo_documento ?? 'Cedula Ciudadania';
  const generoDb = genderAppToDb[userData.genero ?? 'Otro'] ?? 'Otro';

  return {
    nombre: userData.nombre,
    apellido: userData.apellido,
    correo: userData.email,
    tipo_documento: tipoDocumentoDb,
    num_documento: userData.num_documento,
    fecha_nacimiento: userData.fecha_nacimiento ? new Date(userData.fecha_nacimiento) : null,
    genero: generoDb,
    telefono: userData.telefono ? Number(String(userData.telefono).replace(/[^0-9]/g, '')) : null,
    direccion: userData.direccion,
    ciudad_residencia: userData.ciudad_residencia,
    pais_residencia: userData.pais_residencia,
    id_rol: roleId,
    lugar_nacimiento: userData.lugar_nacimiento ?? null,
  };
};

export const createUser = async (userData) => {
  const connection = await getConnection();

  try {
    const dbFields = await mapAppUserToDbFields(userData);

    const hashedPassword = await hashPassword(userData.contrasena);

    const [result] = await connection.execute(
      `INSERT INTO Usuario (
        nombre,
        apellido,
        tipo_documento,
        num_documento,
        fecha_nacimiento,
        lugar_nacimiento,
        genero,
        telefono,
        correo,
        direccion,
        ciudad_residencia,
        pais_residencia,
        contrasena,
        id_rol
      ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
      [
        dbFields.nombre,
        dbFields.apellido,
        dbFields.tipo_documento,
        dbFields.num_documento,
        dbFields.fecha_nacimiento,
        dbFields.lugar_nacimiento,
        dbFields.genero,
        dbFields.telefono,
        dbFields.correo,
        dbFields.direccion,
        dbFields.ciudad_residencia,
        dbFields.pais_residencia,
        hashedPassword,
        dbFields.id_rol,
      ]
    );

    return await findUserById(result.insertId);
  } finally {
    connection.release();
  }
};

export const updateUser = async (idUsuario, userData) => {
  const existingUser = await findUserById(idUsuario);
  if (!existingUser) return null;

  const connection = await getConnection();

  try {
    const dbFields = await mapAppUserToDbFields({ ...existingUser, ...userData });

    const fields = [];
    const values = [];

    const fieldMapping = [
      { column: 'nombre', keys: ['nombre'] },
      { column: 'apellido', keys: ['apellido'] },
      { column: 'tipo_documento', keys: ['tipo_documento'] },
      { column: 'num_documento', keys: ['num_documento'] },
      { column: 'fecha_nacimiento', keys: ['fecha_nacimiento'] },
      { column: 'lugar_nacimiento', keys: ['lugar_nacimiento'] },
      { column: 'genero', keys: ['genero'] },
      { column: 'telefono', keys: ['telefono'] },
      { column: 'correo', keys: ['correo', 'email'] },
      { column: 'direccion', keys: ['direccion'] },
      { column: 'ciudad_residencia', keys: ['ciudad_residencia'] },
      { column: 'pais_residencia', keys: ['pais_residencia'] },
      { column: 'id_rol', keys: ['id_rol', 'rol'] },
      { column: 'activo', keys: ['activo'] },
    ];

    for (const { column, keys } of fieldMapping) {
      if (!(column in dbFields)) continue;

      const hasUpdate = keys.some((key) => userData[key] !== undefined);
      if (!hasUpdate) continue;

      fields.push(`${column} = ?`);
      values.push(dbFields[column]);
    }

    if (userData.contrasena) {
      const hashedPassword = await hashPassword(userData.contrasena);
      fields.push('contrasena = ?');
      values.push(hashedPassword);
    }

    if (!fields.length) {
      return existingUser;
    }

    values.push(idUsuario);

    await connection.execute(
      `UPDATE Usuario
       SET ${fields.join(', ')}
       WHERE id_usuario = ?`,
      values
    );

    return await findUserById(idUsuario);
  } finally {
    connection.release();
  }
};

export const deleteUser = async (idUsuario) => {
  const user = await findUserById(idUsuario);
  if (!user) return false;

  if (user.rol === 'superadministrador') {
    const error = new Error('No se permite eliminar un superadministrador');
    error.status = 403;
    throw error;
  }

  const connection = await getConnection();

  try {
    const [result] = await connection.execute(
      `DELETE FROM Usuario WHERE id_usuario = ?`,
      [idUsuario]
    );
    return result.affectedRows > 0;
  } finally {
    connection.release();
  }
};
