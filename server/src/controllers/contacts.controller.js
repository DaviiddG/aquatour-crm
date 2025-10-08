import {
  findAllContacts,
  findContactById,
  createContact,
  updateContact,
  deleteContact,
} from '../services/contacts.service.js';

export const getContacts = async (_req, res, next) => {
  try {
    const contacts = await findAllContacts();
    res.json({ ok: true, contacts });
  } catch (error) {
    next(error);
  }
};

export const getContactById = async (req, res, next) => {
  try {
    const { idContacto } = req.params;
    const contact = await findContactById(idContacto);

    if (!contact) {
      return res.status(404).json({ ok: false, error: 'Contacto no encontrado' });
    }

    res.json({ ok: true, contact });
  } catch (error) {
    next(error);
  }
};

export const createContactController = async (req, res, next) => {
  try {
    const newContact = await createContact(req.body);
    res.status(201).json({ ok: true, contact: newContact });
  } catch (error) {
    next(error);
  }
};

export const updateContactController = async (req, res, next) => {
  try {
    const { idContacto } = req.params;
    const updatedContact = await updateContact(idContacto, req.body);

    if (!updatedContact) {
      return res.status(404).json({ ok: false, error: 'Contacto no encontrado' });
    }

    res.json({ ok: true, contact: updatedContact });
  } catch (error) {
    next(error);
  }
};

export const deleteContactController = async (req, res, next) => {
  try {
    const { idContacto } = req.params;
    const deleted = await deleteContact(idContacto);

    if (!deleted) {
      return res.status(404).json({ ok: false, error: 'Contacto no encontrado' });
    }

    res.json({ ok: true, deleted: true });
  } catch (error) {
    next(error);
  }
};
