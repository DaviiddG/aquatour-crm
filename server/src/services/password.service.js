import bcrypt from 'bcryptjs';

const DEFAULT_SALT_ROUNDS = 10;
const saltRounds = Number(process.env.BCRYPT_SALT_ROUNDS ?? DEFAULT_SALT_ROUNDS);

export const hashPassword = async (plainPassword) => {
  if (!plainPassword) return null;
  return bcrypt.hash(plainPassword, saltRounds);
};

export const verifyPassword = async (plainPassword, hashedPassword) => {
  if (!plainPassword || !hashedPassword) return false;

  const isBcryptHash = hashedPassword.startsWith('$2a$') || hashedPassword.startsWith('$2b$');

  if (!isBcryptHash) {
    return plainPassword === hashedPassword;
  }

  return bcrypt.compare(plainPassword, hashedPassword);
};
