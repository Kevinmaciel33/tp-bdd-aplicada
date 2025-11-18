USE Com2900G10;
GO

PRINT 'Limpiando roles antiguos...';

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Rol_AdminGeneral' AND type = 'R')
    DROP ROLE Rol_AdminGeneral;

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Rol_AdminBancario' AND type = 'R')
    DROP ROLE Rol_AdminBancario;

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Rol_AdminOperativo' AND type = 'R')
    DROP ROLE Rol_AdminOperativo;

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Rol_Sistemas' AND type = 'R')
    DROP ROLE Rol_Sistemas;
GO

PRINT 'Creando Roles...';

CREATE ROLE Rol_AdminGeneral;
CREATE ROLE Rol_AdminBancario;
CREATE ROLE Rol_AdminOperativo;
CREATE ROLE Rol_Sistemas;
GO

PRINT 'Asignando permisos: Actualización de UF';
GRANT UPDATE ON tpo.UnidadFuncional TO Rol_AdminGeneral;
GRANT UPDATE ON tpo.UnidadFuncional TO Rol_AdminOperativo;

PRINT 'Asignando permisos: Importación Bancaria';
GRANT EXECUTE ON tpo.sp_importarPagos TO Rol_AdminBancario;
GRANT INSERT, UPDATE ON tpo.Pago TO Rol_AdminBancario; 

PRINT 'Asignando permisos: Generación de Reportes';

-- ROL: Admin General
GRANT EXECUTE ON tpo.sp_reporte_flujo_caja TO Rol_AdminGeneral;
GRANT EXECUTE ON tpo.sp_reporte_recaudacion_mensual TO Rol_AdminGeneral;
GRANT EXECUTE ON tpo.sp_reporte_recaudacion_desA TO Rol_AdminGeneral;
GRANT EXECUTE ON tpo.sp_reporte_top5_gastos_ingresos TO Rol_AdminGeneral;
GRANT EXECUTE ON tpo.sp_reporte_top3_morosidad TO Rol_AdminGeneral;
GRANT EXECUTE ON tpo.sp_reporte_dias_entre_pagos TO Rol_AdminGeneral;

-- ROL: Admin Bancario
GRANT EXECUTE ON tpo.sp_reporte_flujo_caja TO Rol_AdminBancario;
GRANT EXECUTE ON tpo.sp_reporte_recaudacion_mensual TO Rol_AdminBancario;
GRANT EXECUTE ON tpo.sp_reporte_recaudacion_desA TO Rol_AdminBancario;
GRANT EXECUTE ON tpo.sp_reporte_top5_gastos_ingresos TO Rol_AdminBancario;
GRANT EXECUTE ON tpo.sp_reporte_top3_morosidad TO Rol_AdminBancario;
GRANT EXECUTE ON tpo.sp_reporte_dias_entre_pagos TO Rol_AdminBancario;

-- ROL: Admin Operativo
GRANT EXECUTE ON tpo.sp_reporte_flujo_caja TO Rol_AdminOperativo;
GRANT EXECUTE ON tpo.sp_reporte_recaudacion_mensual TO Rol_AdminOperativo;
GRANT EXECUTE ON tpo.sp_reporte_recaudacion_desA TO Rol_AdminOperativo;
GRANT EXECUTE ON tpo.sp_reporte_top5_gastos_ingresos TO Rol_AdminOperativo;
GRANT EXECUTE ON tpo.sp_reporte_top3_morosidad TO Rol_AdminOperativo;
GRANT EXECUTE ON tpo.sp_reporte_dias_entre_pagos TO Rol_AdminOperativo;

-- ROL: Sistemas (Solo tiene permisos de Reportes según el cuadro)
GRANT EXECUTE ON tpo.sp_reporte_flujo_caja TO Rol_Sistemas;
GRANT EXECUTE ON tpo.sp_reporte_recaudacion_mensual TO Rol_Sistemas;
GRANT EXECUTE ON tpo.sp_reporte_recaudacion_desA TO Rol_Sistemas;
GRANT EXECUTE ON tpo.sp_reporte_top5_gastos_ingresos TO Rol_Sistemas;
GRANT EXECUTE ON tpo.sp_reporte_top3_morosidad TO Rol_Sistemas;
GRANT EXECUTE ON tpo.sp_reporte_dias_entre_pagos TO Rol_Sistemas;

GRANT VIEW DEFINITION ON SCHEMA::tpo TO Rol_Sistemas;


PRINT 'Asignando permisos de Criptografía para Reportes';

GRANT CONTROL ON CERTIFICATE::CertificadoTP TO Rol_AdminGeneral;
GRANT CONTROL ON CERTIFICATE::CertificadoTP TO Rol_AdminBancario;
GRANT CONTROL ON CERTIFICATE::CertificadoTP TO Rol_AdminOperativo;
GRANT CONTROL ON CERTIFICATE::CertificadoTP TO Rol_Sistemas;

GO

PRINT 'ROLES Y PERMISOS CONFIGURADOS CORRECTAMENTE';