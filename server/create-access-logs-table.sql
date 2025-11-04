-- Tabla para registrar los accesos al sistema
CREATE TABLE IF NOT EXISTS access_logs (
  id_log INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario INT NOT NULL,
  nombre_usuario VARCHAR(255) NOT NULL,
  rol_usuario VARCHAR(50) NOT NULL,
  fecha_hora_ingreso DATETIME NOT NULL,
  fecha_hora_salida DATETIME NULL,
  duracion_sesion VARCHAR(50) NULL,
  ip_address VARCHAR(45) NOT NULL,
  navegador VARCHAR(255) NULL,
  sistema_operativo VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario) ON DELETE CASCADE,
  INDEX idx_usuario (id_usuario),
  INDEX idx_fecha_ingreso (fecha_hora_ingreso),
  INDEX idx_activos (fecha_hora_salida)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Comentarios de la tabla
ALTER TABLE access_logs COMMENT = 'Registro de accesos al sistema para auditoría';
