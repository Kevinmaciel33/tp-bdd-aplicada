/*
Este script crea la vista para a partir de ella generar el csv de salida del Detalle Expensa.
18/11/2025
Com2900G10
Grupo 10
Bases de datos aplicadas
Integrantes:
-Kevin Maciel
-Marcos kouvach
-Agostina salas
-Keila Álvarez Da Silva*/
CREATE OR ALTER VIEW tpo.vw_ReporteDetalleExpensa
AS
SELECT              
    de.IdExpensa,
	uf.IdUf,
	de.Porcentaje AS [Porcentaje],
    uf.Piso + '-' + uf.Depto AS [Piso-Depto.],
	
	CONVERT(VARCHAR(MAX), DECRYPTBYKEY(p.Nombre)) + ' ' + 
    CONVERT(VARCHAR(MAX), DECRYPTBYKEY(p.Apellido)) AS Propietario,
	
	de.SaldoAnterior AS [Saldo_Anterior],
	de.PagosRecibidos AS [Pagos_Recibidos],
	de.Deuda,
	de.InteresesMora AS [Interes_Mora],
	de.TotalOrd AS [Expensas_Ordinarias],
	de.TotalExt AS [Expensas_Extraordinarias],
    e.mes,
    e.IdConsorcio,
    COALESCE(
        (SELECT COUNT(*) FROM tpo.EspacioExtra WHERE IdUf = uf.IdUf AND TipoEspacio = 'Cochera'), 0
    ) AS Cocheras,
    COALESCE(
        (SELECT COUNT(*) FROM tpo.EspacioExtra WHERE IdUf = uf.IdUf AND TipoEspacio = 'Baulera'), 0
    ) AS Bauleras,

	de.Total AS [Total]
FROM 
    tpo.DetalleExpensa de
    JOIN tpo.Expensa e ON e.IdConsorcio = de.IdExpensa 
    JOIN tpo.Consorcio c ON c.IdConsorcio = e.IdConsorcio
    JOIN tpo.UnidadFuncional uf ON uf.IdConsorcio = c.IdConsorcio
    JOIN tpo.Persona p ON CONVERT(VARCHAR(MAX), DECRYPTBYKEY(p.Cuenta)) = uf.Cuenta
    JOIN tpo.TipoPersona tp ON tp.IdTipo = p.IdTipo
GO
