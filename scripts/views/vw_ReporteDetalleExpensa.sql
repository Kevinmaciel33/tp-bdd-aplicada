CREATE OR ALTER VIEW tpo.vw_ReporteDetalleExpensa
AS
SELECT              
    de.IdExpensa,
	uf.IdUf,
	de.Porcentaje AS [Porcentaje (%)],
    uf.Piso + '-' + uf.Depto AS [Piso-Depto.],
	
	CONVERT(VARCHAR(MAX), DECRYPTBYKEY(p.Nombre)) + ' ' + 
    CONVERT(VARCHAR(MAX), DECRYPTBYKEY(p.Apellido)) AS Propietario,
	
	de.SaldoAnterior AS [Saldo Anterior Abonado],
	de.PagosRecibidos AS [Pagos Recibidos],
	de.Deuda,
	de.InteresesMora AS [Interés por Mora],
	de.TotalOrd AS [Expensas Ordinarias],
	de.TotalExt AS [Expensas Extraordinarias],

    COALESCE(
        (SELECT COUNT(*) FROM tpo.EspacioExtra WHERE IdUf = uf.IdUf AND TipoEspacio = 'Cochera'), 0
    ) AS Cocheras,
    COALESCE(
        (SELECT COUNT(*) FROM tpo.EspacioExtra WHERE IdUf = uf.IdUf AND TipoEspacio = 'Baulera'), 0
    ) AS Bauleras,

	de.Total AS [Total a Pagar]

FROM 
    tpo.DetalleExpensa de
    JOIN tpo.Expensa e ON e.IdConsorcio = de.IdExpensa 
    JOIN tpo.Consorcio c ON c.IdConsorcio = e.IdConsorcio
    JOIN tpo.UnidadFuncional uf ON uf.IdConsorcio = c.IdConsorcio
    JOIN tpo.Persona p ON CONVERT(VARCHAR(MAX), DECRYPTBYKEY(p.Cuenta)) = uf.Cuenta
    JOIN tpo.TipoPersona tp ON tp.IdTipo = p.IdTipo
GO