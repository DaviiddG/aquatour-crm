import {
  findAllUsers,
  findUserById,
  findByEmail,
  findByDocument,
  findByPhone,
  createUser,
  updateUser,
  deleteUser,
} from '../services/users.service.js';

export const getUsers = async (_req, res, next) => {
  try {
    const users = await findAllUsers();
    res.json({ ok: true, users });
  } catch (error) {
    next(error);
  }
};

export const getUserById = async (req, res, next) => {
  try {
    const { idUsuario } = req.params;
    const user = await findUserById(idUsuario);

    if (!user) {
      return res.status(404).json({ ok: false, error: 'Usuario no encontrado' });
    }

    res.json({ ok: true, user });
  } catch (error) {
    next(error);
  }
};

export const checkEmail = async (req, res, next) => {
  try {
    const { email } = req.params;
    const { exclude } = req.query;
    const user = await findByEmail(email, exclude);
    res.json({ ok: true, exists: Boolean(user) });
  } catch (error) {
    next(error);
  }
};

export const checkDocument = async (req, res, next) => {
  try {
    const { numDocumento } = req.params;
    const { exclude } = req.query;
    const user = await findByDocument(numDocumento, exclude);
    res.json({ ok: true, exists: Boolean(user), user: user ? { nombre: user.nombre, apellido: user.apellido } : null });
  } catch (error) {
    next(error);
  }
};

export const checkPhone = async (req, res, next) => {
  try {
    const { telefono } = req.params;
    const { exclude } = req.query;
    const cleanPhone = String(telefono).replace(/[^0-9]/g, '');
    const user = await findByPhone(cleanPhone, exclude);
    res.json({ ok: true, exists: Boolean(user), user: user ? { nombre: user.nombre, apellido: user.apellido } : null });
  } catch (error) {
    next(error);
  }
};

export const createUserController = async (req, res, next) => {
  try {
    const existing = await findByEmail(req.body.email);
    if (existing) {
      return res.status(409).json({ ok: false, error: 'El email ya está registrado' });
    }

    const newUser = await createUser(req.body);
    res.status(201).json({ ok: true, user: newUser });
  } catch (error) {
    next(error);
  }
};

export const updateUserController = async (req, res, next) => {
  try {
    const { idUsuario } = req.params;
    const updatedUser = await updateUser(idUsuario, req.body);

    if (!updatedUser) {
      return res.status(404).json({ ok: false, error: 'Usuario no encontrado' });
    }

    res.json({ ok: true, user: updatedUser });
  } catch (error) {
    if (error.status === 409) {
      return res.status(409).json({ ok: false, error: error.message });
    }
    next(error);
  }
};

export const deleteUserController = async (req, res, next) => {
  try {
    const { idUsuario } = req.params;
    const deleted = await deleteUser(idUsuario);

    if (!deleted) {
      return res.status(404).json({ ok: false, error: 'Usuario no encontrado' });
    }

    res.json({ ok: true, deleted: true });
  } catch (error) {
    next(error);
  }
};
