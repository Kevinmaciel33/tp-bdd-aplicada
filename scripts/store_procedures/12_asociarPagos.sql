/*
Este script asocia los pagos a las unidades funcionales por cuenta.
18/11/2025
Com2900G10
Grupo 10
Bases de datos aplicadas
Integrantes:
-Kevin Maciel
-Marcos kouvach
-Agostina salas
-Keila Álvarez Da Silva*/
CREATE OR ALTER PROCEDURE [tpo].[sp_asociarPagos]
as
begin
SET NOCOUNT ON;
	UPDATE p
	SET p.IdUf = uf.IdUf, p.IdConsorcio=uf.IdConsorcio
	FROM tpo.Pago p
	INNER JOIN tpo.UnidadFuncional uf on p.Cuenta = uf.Cuenta
	WHERE p.IdUf IS NULL;

	DECLARE @FilasActualizadas INT = @@ROWCOUNT;
    PRINT 'Proceso completado. Pagos asociados a UF: ' + CAST(@FilasActualizadas AS VARCHAR(10));
end
go
