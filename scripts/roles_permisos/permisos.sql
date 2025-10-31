-- Permisos de Actualización de datos de UF
GRANT UPDATE ON Datos_UF TO "Administrativo general";
GRANT UPDATE ON Datos_UF TO "Administrativo operativo";

-- Permisos de Importación de información bancaria
GRANT INSERT ON Informacion_Bancaria TO "Administrativo Bancario";

-- Permisos de Generación de reportes
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "Administrativo general";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "Administrativo Bancario";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "Administrativo operativo";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "Sistemas";