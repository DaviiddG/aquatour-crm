export const errorHandler = (err, _req, res, _next) => {
  console.error('❌ API Error:', err);

  const status = err.status || 500;
  const message = err.message || 'Error interno del servidor';

  res.status(status).json({
    ok: false,
    error: message,
  });
};
