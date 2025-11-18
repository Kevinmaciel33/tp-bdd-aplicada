CREATE OR ALTER VIEW tpo.vw_ReporteExpensa AS
WITH Movimientos AS (
    SELECT
        f.IdExpensa,
        f.Tipo AS TipoMovimiento,
        f.Detalle AS DetalleMovimiento,
        f.Importe AS ImporteMovimiento,
		NULL AS UFDeudor
    FROM tpo.Factura f

    UNION ALL

    SELECT
        d.IdExpensa,
        'DEUDOR' AS TipoMovimiento,
        NULL AS campo,
        d.Deuda AS ImporteMovimiento,
		d.IdUf AS UFDeudor
    FROM tpo.DetalleExpensa d
)
SELECT 
    'Administración Altos De Saint Just' AS NombreAdministracion,
    'Arieta 1234, GBA' AS DireccionAdministracion,
    '011-5555-000' AS TelefonoAdministracion,
    'administracion@altosdesaintjust.com.ar' AS EmailAdministracion,
	'Formas de pago: Depósito o transferencia a la cuenta corriente del Banco N° 123456' AS FormaDePago,

    -- Datos dinámicos
    c.IdConsorcio,
    c.Nombre AS NombreConsorcio,
    e.Mes,
    e.FechaGeneracion,
    e.vto1,
    e.vto2,
    e.SaldoAnterior,
    e.IngresosPagoTermino,
    e.IngresosPagoAdeudado,
    e.IngresosPagoAdelantado,
    e.Egresos,
    e.SaldoCierre,

    m.TipoMovimiento,
    m.DetalleMovimiento,
    m.ImporteMovimiento,
	m.UFDeudor

FROM tpo.Expensa e
INNER JOIN tpo.Consorcio c ON c.IdConsorcio = e.IdConsorcio
LEFT JOIN Movimientos m ON m.IdExpensa = e.IdExpensa
WHERE m.ImporteMovimiento > 0