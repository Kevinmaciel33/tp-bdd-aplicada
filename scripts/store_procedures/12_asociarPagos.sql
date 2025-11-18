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