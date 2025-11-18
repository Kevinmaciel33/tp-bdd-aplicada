--CREACION DE REPORTES

--1) PRIMER REPORTE- FLUJO DE CAJA SEMANAL
--RECAUDACION POR PAGOS ORDINARIOS Y EXTRAORDINARIOS DE CADA SEMANA 
--PROMEDIO SEMANAL
--ACUMULADO PROGRESIVO

CREATE OR ALTER PROCEDURE [tpo].[sp_reporte_flujo_caja]
	@FechaInicio DATE,
	@FechaFin DATE,
	@IdConsorcio INT
AS
BEGIN
	BEGIN TRY
	SELECT
		DATEPART(WEEK, p.FechaPago) AS Semana, 
		SUM(ISNULL(de.TotalOrd, 0)) AS TotalOrdinario,
		SUM(ISNULL(de.TotalExt, 0)) AS TotalExtraordinario,
		SUM(ISNULL(p.Importe, 0)) AS TotalSemanal,
		AVG(SUM(ISNULL(p.Importe, 0))) OVER() AS PromedioGeneral, 
		SUM(SUM(ISNULL(p.Importe, 0))) OVER(ORDER BY DATEPART(WEEK, p.FechaPago)) AS Acumulado
	FROM tpo.Pago p
	INNER JOIN tpo.DetalleExpensa de ON p.IdDetalleExp = de.IdDetalle
	INNER JOIN tpo.Expensa e ON e.IdExpensa = de.IdExpensa
	WHERE e.IdConsorcio = @IdConsorcio
	 AND p.FechaPago BETWEEN @FechaInicio AND @FechaFin
	GROUP BY DATEPART(WEEK, p.FechaPago)
	ORDER BY Semana;
	END TRY
	BEGIN CATCH
		PRINT 'ERROR en sp_reporte_flujo_caja:'
		PRINT ERROR_MESSAGE();
		THROW;
	END CATCH
END;
GO


--2) SEGUNDO REPORTE - TOTAL DE RECAUDACION MENSUAL X DEPTO 
--FORMATO TABLA CRUZADA POR MES Y NUMERO DE UF

CREATE OR ALTER PROCEDURE [tpo].[sp_reporte_recaudacion_mensual]
	@Anio INT, 
	@IdConsorcio INT
AS
BEGIN
	BEGIN TRY
	SELECT *
	FROM (
		  SELECT
				MONTH(p.FechaPago) AS Mes, 
				uf.NroUf,
				p.Importe
		  FROM tpo.Pago p
		  INNER JOIN tpo.DetalleExpensa de ON p.IdDetalleExp = de.IdDetalle
		  INNER JOIN tpo.UnidadFuncional uf ON de.IdUf = uf.IdUf
		  INNER JOIN tpo.Expensa e ON de.IdExpensa = e.IdExpensa
		  WHERE e.IdConsorcio = @IdConsorcio
			AND YEAR(p.FechaPago) = @Anio
		) AS DatosPagos
	PIVOT ( 
	       SUM(Importe) FOR Mes IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
		   ) AS PivotRecaudacion;
	END TRY
	BEGIN CATCH
		PRINT 'ERROR en sp_reporte_recaudacion_mensual:'
		PRINT ERROR_MESSAGE();
		THROW;
	END CATCH
END;
GO

--3) TERCER REPORTE - RECAUDACION TOTAL DESAGREGADA
--SEGUN PROCEDENCIA (ORDINARIO, EXTRAORDINARIO, ETC.) SEGUN PERIODO

CREATE OR ALTER PROCEDURE [tpo].[sp_reporte_recaudacion_desA]
	@FechaInicio DATE,
	@FechaFin DATE,
	@IdConsorcio INT
AS
BEGIN
	BEGIN TRY
	SET ANSI_WARNINGS OFF;

	SELECT
		'Ordinario' AS Tipo,
		SUM(ISNULL(de.TotalOrd, 0)) AS Total
	FROM tpo.DetalleExpensa de
	INNER JOIN tpo.Expensa e ON e.IdExpensa = de.IdExpensa
	WHERE e.IdConsorcio = @IdConsorcio
	 AND e.FechaGeneracion BETWEEN @FechaInicio AND @FechaFin

	 UNION ALL

	 SELECT 
		'Extraordinario' AS Tipo,
		SUM(ISNULL(de.TotalExt, 0)) AS Total
	FROM tpo.DetalleExpensa de
	INNER JOIN tpo.Expensa e ON e.IdExpensa = de.IdExpensa
	WHERE e.IdConsorcio = @IdConsorcio
	 AND e.FechaGeneracion BETWEEN @FechaInicio AND @FechaFin

	FOR XML AUTO, ROOT('Recaudacion')

	SET ANSI_WARNINGS ON;
	END TRY
	BEGIN CATCH
		PRINT 'ERROR en sp_reporte_recaudacion_desA'
		PRINT ERROR_MESSAGE();
		THROW;
	END CATCH
END;
GO

--4) CUARTO REPORTE - TOP 5 MESES DE MAYORES GASTOS Y TOP 5 MESES DE MAYORES INGRESOS

CREATE OR ALTER PROCEDURE [tpo].[sp_reporte_top5_gastos_ingresos]
	@IdConsorcio INT
AS
BEGIN
 BEGIN TRY
	SELECT TOP 5
        CASE WHEN f.Tipo = 'O' THEN 'Gasto Ordinario' ELSE 'Gasto Extraordinario' END AS Tipo,
        f.Mes,
        SUM(f.Importe) AS Total
    FROM tpo.Factura f
    INNER JOIN tpo.Expensa e ON f.IdExpensa = e.IdExpensa
    WHERE e.IdConsorcio = @IdConsorcio
    GROUP BY f.Tipo, f.Mes
    ORDER BY Total DESC;


	SELECT TOP 5 
        'Ingreso' AS Tipo,
        MONTH(p.FechaPago) AS Mes,
        SUM(p.Importe) AS Total
    FROM tpo.Pago p
    INNER JOIN tpo.DetalleExpensa de ON p.IdDetalleExp = de.IdDetalle
    INNER JOIN tpo.Expensa e ON e.IdExpensa = de.IdExpensa
    WHERE e.IdConsorcio = @IdConsorcio
    GROUP BY MONTH(p.FechaPago)
    ORDER BY Total DESC;

 END TRY
 BEGIN CATCH
	PRINT 'ERROR en sp_reporte_top5_gastos_ingresos:'
	PRINT ERROR_MESSAGE();
	THROW;
 END CATCH
END;
GO


--5) QUINTO REPORTE - 3 PROPIETARIOS CON MAYOR MOROSIDAD
--INFO DE CONTACTO Y DNI DE LOS PROPIETARIOS PARA CONTACTO DE LA ADMINISTRACION
CREATE OR ALTER PROCEDURE [tpo].[sp_reporte_top3_morosidad]
AS
BEGIN
	BEGIN TRY 

	OPEN SYMMETRIC KEY ClaveTP 
    DECRYPTION BY CERTIFICATE CertificadoTP;

	;WITH DeudaPorPropietario AS (
	SELECT
            per.DNI,
            CONVERT(VARCHAR(MAX), DECRYPTBYKEY(per.Nombre)) AS Nombre,
            CONVERT(VARCHAR(MAX), DECRYPTBYKEY(per.Apellido)) AS Apellido,
            CONVERT(VARCHAR(MAX), DECRYPTBYKEY(per.Email)) AS Email,
            CONVERT(VARCHAR(MAX), DECRYPTBYKEY(per.Telefono)) AS Telefono,
            SUM(ISNULL(de.Total,0)) AS TotalExpensas,
            SUM(ISNULL(pg.Importe,0)) AS TotalPagos,
            SUM(ISNULL(de.Total,0)) - SUM(ISNULL(pg.Importe,0)) AS Deuda
        FROM tpo.UnidadFuncional uf
        INNER JOIN tpo.Persona per ON uf.Cuenta = per.Cuenta
        LEFT JOIN tpo.DetalleExpensa de ON uf.IdUf = de.IdUf
        LEFT JOIN tpo.Pago pg ON de.IdDetalle = pg.IdDetalleExp
        GROUP BY per.DNI, per.Nombre, per.Apellido, per.Email, per.Telefono
    )
	SELECT TOP 3 *
	FROM DeudaPorPropietario
	ORDER BY Deuda DESC;
	CLOSE SYMMETRIC KEY ClaveTP;
	END TRY
	BEGIN CATCH
		IF EXISTS (
			SELECT 1 
			FROM sys.openkeys 
			WHERE key_name = 'ClaveTP'
		)
			CLOSE SYMMETRIC KEY ClaveTP;

		PRINT 'ERROR en sp_reporte_top3_morosidad:'
		PRINT ERROR_MESSAGE();
		THROW;
	END CATCH
END;
GO

--6) SEXTO REPORTE - FECHAS DE PAGO DE EXPENSAS ORDINARIAS DE CADA UF
-- + CANTIDAD DE DIAS QUE PASAN ENTRE UN PAGO Y EL SIGUIENTE 
CREATE OR ALTER PROCEDURE [tpo].[sp_reporte_dias_entre_pagos]
    @IdConsorcio INT,
    @IdUf INT,
    @FechaDesde DATE
AS
BEGIN
	BEGIN TRY
    WITH PagosOrdenados AS (
        SELECT
            de.IdUf,
            p.FechaPago,
            LAG(p.FechaPago) OVER (PARTITION BY de.IdUf ORDER BY p.FechaPago) AS PagoAnterior
        FROM tpo.Pago p
        INNER JOIN tpo.DetalleExpensa de ON p.IdDetalleExp = de.IdDetalle
        INNER JOIN tpo.Expensa e ON e.IdExpensa = de.IdExpensa
        WHERE e.IdConsorcio = @IdConsorcio
          AND de.IdUf = @IdUf
          AND p.FechaPago >= @FechaDesde
    )
    SELECT 
        IdUf,
        FechaPago,
        DATEDIFF(DAY, PagoAnterior, FechaPago) AS DiasEntrePagos
    FROM PagosOrdenados
    FOR XML AUTO, ROOT('Pagos');

	END TRY
	BEGIN CATCH
		PRINT 'ERROR en sp_reporte_dias_entre_pagos:' 
		PRINT ERROR_MESSAGE();
		THROW;
	END CATCH
END;
GO


