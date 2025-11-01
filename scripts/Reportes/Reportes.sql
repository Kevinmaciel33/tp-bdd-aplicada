--PUNTO 6 REPORTES

--1) PRIMER REPORTE- FLUJO DE CAJA SEMANAL
--RECAUDACION POR PAGOS ORDINARIOS Y EXTRAORDINARIOS DE CADA SEMANA 
--PROMEDIO SEMANAL
--ACUMULADO PROGRESIVO

CREATE OR ALTER PROCEDURE sp_reporte_flujo_caja
	@FechaInicio DATE,
	@FechaFin DATE,
	@IdConsorcio INT
AS
BEGIN
	SELECT
		DATEPART(WEEK, p.FechaPago) AS Semana, 
		SUM(CASE WHEN de.TipoGasto = 'O' THEN p.Importe ELSE 0 END) AS TotalOrdinario,
		SUM(CASE WHEN de.TipoGasto = 'E' THEN p.importe ELSE 0 END) AS TotalExtraordinario,
		SUM(p.importe) AS TotalSemanal,
		AVG(SUM(p.importe)) OVER() AS PromedioGeneral, 
		SUM(SUM(p.importe)) OVER(ORDER BY DATEPART(WEEK, p.FechaPago)) AS Acumulado
	FROM dbo.Pago p
	INNER JOIN dbo.DetalleExpensa de ON p.IdDetalleExp = de.IdDetalle
	INNER JOIN dbo.Expensa e ON e.IdExpensa = de.IdExpensa
	WHERE e.IdConsorcio = @IdConsorcio
	 AND p.FechaPago BETWEEN @FechaInicio AND @FechaFin
	GROUP BY DATEPART(WEEK, p.FechaPago)
	ORDER BY Semana;
END
GO
--Para un consorcio especifico
--Analiza los pagos de un consorcio en un rango de fechas y los agrupa por semana
--TotalOrdinario: suma de pagos de gastos ordinarios (o) en esa semana
--TotalExtraordinario: suma de pagos de gastos extraordinarios (e) en esa semana
--TotalSemanal: suma de todos los pagos de esa semana
--PromedioGeneral: Promedio de todas las semanas (el mismo valor en todas las filas)
--Acumulado: Suma acumulada semana a semana (va sumando los totales progresivamente)

--Tablas que usa son 3: Pago, DetalleExpensa (para tipo O o E) y Expensa (tiene el consorcio)
--Filtros: solo pagos del consorcio especificado y solo pagos entre las fechas fechaini y fechafin
--INNER JOIN DE LAS 3 TABLAS
--Se agrupan por semana y se ordenan por semana


--2) SEGUNDO REPORTE - TOTAL DE RECAUDACION MENSUAL X DEPTO 
--FORMATO TABLA CRUZADA POR MES Y NUMERO DE UF

CREATE OR ALTER PROCEDURE sp_reporte_recaudacion_mensual
	@Anio INT, 
	@IdConsorcio INT,
	@TipoGasto CHAR(1)
AS
BEGIN
	SELECT *
	FROM (
		  SELECT
				MONTH(p.FechaPago) AS Mes, 
				uf.NroUf,
				p.Importe
		  FROM dbo.Pago p
		  INNER JOIN dbo.UnidadFuncional uf ON p.IdUf = uf.IdUf
		  INNER JOIN dbo.DetalleExpensa de ON p.IdDetalleExp = de.IdDetalle
		  INNER JOIN dbo.Expensa e ON e.IdExpensa = de.IdExpensa
		  WHERE e.IdConsorcio = @IdConsorcio
			AND YEAR(p.FechaPago) = @Anio
			AND de.TipoGasto = @TipoGasto
		) AS DatosPagos
	PIVOT ( 
	       SUM(Importe) FOR Mes IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
		   ) AS PivotRecaudacion;
END
go
--Genera un reporte de recaudacion mensual por departamento en tabla cruzada(pivot)
--Filas: DEPTO NRO UF
--Columnas: 12 MESES DEL AÑO
--Valores/contenido: Total recaudado(suma del importe)
--FILTROS: solo un consorcio especifico, solo pagos de ese año y solo 1 tipo de gasto (Ordinario o extraordinario)

--Tablas 4: pago-uf-detalleexpensa-expensa (inner join en estos)
	
--3) TERCER REPORTE - RECAUDACION TOTAL DESAGREGADA
--SEGUN PROCEDENCIA (ORDINARIO, EXTRAORDINARIO, ETC.) SEGUN PERIODO

CREATE OR ALTER PROCEDURE sp_reporte_recaudacion_desA
	@FechaInicio DATE,
	@FechaFin DATE,
	@IdConsorcio INT
AS
BEGIN
	SELECT
		de.TipoGasto,
		SUM(p.Importe) AS Total
	FROM dbo.Pago p 
	INNER JOIN dbo.DetalleExpensa de ON p.IdDetalleExp = de.IdDetalle
	INNER JOIN dbo.Expensa e ON e.IdExpensa = de.IdExpensa
	WHERE e.IdConsorcio = @IdConsorcio
	 AND p.FechaPago BETWEEN @FechaInicio AND @FechaFin
	GROUP BY de.TipoGasto
	FOR XML AUTO, ROOT('Recaudacion')
END
go

--Genera un reporte de recaudacion total desagregada por tipo de gasto (ext/or)
--en un periodo y lo devuelve en formato XML
--Agrupa los pagos por tipo de gasto y suma el importe total de cada uno
--Filtra por consorcio y rango de fechas (periodo)

--4) CUARTO REPORTE - TOP 5 MESES DE MAYORES GASTOS Y TOP 5 MESES DE MAYORES INGRESOS

CREATE OR ALTER PROCEDURE sp_top5_gastos_ingresos
	@IdConsorcio INT
AS
BEGIN
	SELECT TOP 5 'Gasto' AS Tipo, gor.Mes AS Mes, SUM(gor.Importe) AS Total
	FROM dbo.GastoOrdinario gor
	WHERE gor.IdConsorcio = @IdConsorcio 
	GROUP BY gor.Mes
	ORDER BY Total DESC;

	SELECT TOP 5 'Ingreso' AS Tipo, MONTH(p.FechaPago) AS Mes, SUM(p.Importe) AS Total
	FROM dbo.Pago p
	INNER JOIN dbo.DetalleExpensa de ON p.IdDetalleExp = de.IdDetalle
	INNER JOIN dbo.Expensa e ON e.IdExpensa = de.IdExpensa
	WHERE e.IdConsorcio = @IdConsorcio
	GROUP BY MONTH(p.FechaPago)
	ORDER BY Total DESC;
END
go
--Dos TOP 5: Gastos y Mayores Ingresos de un consorcio
--Gastos: toma los gastos ordinarios de la tabla, suma el importe total de cada
--mes y devuelve los 5 con mayores gasto Tipo-Mes-Total (top 5)
--Mayores ingresos: toma los pagos de la tabla pago, los agrupa por mes 
--(el cual saca de fecha de pago), suma el importe recaudado cada mes y hace top 5
