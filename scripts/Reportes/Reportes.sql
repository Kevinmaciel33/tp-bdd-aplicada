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

CREATE OR ALTER PROCEDURE sp_reporte_top5_gastos_ingresos
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


--5) QUINTO REPORTE - 3 PROPIETARIOS CON MAYOR MOROSIDAD
--INFO DE CONTACTO Y DNI DE LOS PROPIETARIOS PARA CONTACTO DE LA ADMINISTRACION
CREATE OR ALTER PROCEDURE sp_reporte_top3_morosidad
AS
BEGIN
	;WITH DeudaPorPropietario AS (
	SELECT 
		per.id_persona,
		per.Nombre,
		per.Apellido,
		per.DNI,
		per.Email,
		per.Telefono,
		SUM(ISNULL(de.Total, 0)) AS TotalExpensas,
        SUM(ISNULL(pg.Importe, 0)) AS TotalPagos,
        SUM(ISNULL(de.Total, 0)) - SUM(ISNULL(pg.Importe, 0)) AS Deuda
	FROM dbo.persona per
	INNER JOIN dbo.UnidadFuncional UF on per.cuenta = uf.Cuenta
	LEFT JOIN dbo.DetalleExpensa de ON uf.IdUf = de.IdExpensa  -- revisar relación según tu DER
    LEFT JOIN dbo.Pago pg ON uf.IdUf = pg.IdUf
    WHERE per.Tipo = 0  -- solo propietarios
    GROUP BY per.id_persona, per.Dni, per.Nombre, per.Apellido, per.Email, per.Telefono
    )
	SELECT TOP 3
        p.Dni,
        p.Nombre,
        p.Apellido,
        p.Email,
        p.Telefono,
        p.TotalExpensas,
        p.TotalPagos,
        p.Deuda
    FROM DeudaPorPropietario p
    ORDER BY p.Deuda DESC;
END
go
--LOS 3 PROPIETARIOS CON MÁS DEUDA
--Debe incluir personas sin pagos (aquellos que mas deben)
--Si no hay pagos cuenta como 0 en vez de null
--Dni, nombre, apellido, email, telefono (datos del propietario)
--ordenado por deuda descendiente 
--Total expensa (lo que deberia haber pagado)
--TotalPagos (lo que realmente pago)
--Deuda(diferencia) (lo que debe)
--USA CTE(WITH DEUDA POR PROPIETARIO)

--6) SEXTO REPORTE - FECHAS DE PAGO DE EXPENSAS ORDINARIAS DE CADA UF
-- + CANTIDAD DE DIAS QUE PASAN ENTRE UN PAGO Y EL SIGUIENTE 
CREATE OR ALTER PROCEDURE sp_reporte_dias_entre_pagos
    @IdConsorcio INT,
    @IdUf INT,
    @FechaDesde DATE
AS
BEGIN
    WITH PagosOrdenados AS (
        SELECT 
            p.IdUf,
            p.FechaPago,
            LAG(p.FechaPago) OVER (PARTITION BY p.IdUf ORDER BY p.FechaPago) AS PagoAnterior
        FROM dbo.Pago p
        INNER JOIN dbo.DetalleExpensa de ON p.IdDetalleExp = de.IdDetalle
        INNER JOIN dbo.Expensa e ON e.IdExpensa = de.IdExpensa
        WHERE e.IdConsorcio = @IdConsorcio AND p.IdUf = @IdUf AND p.FechaPago >= @FechaDesde
    )
    SELECT 
        IdUf,
        FechaPago,
        DATEDIFF(DAY, PagoAnterior, FechaPago) AS DiasEntrePagos
    FROM PagosOrdenados
    FOR XML AUTO, ROOT('Pagos');
END
--Cuantos dias trancurrieron entre cada pago consecutivo de una misma UF
--DEVUELVE EN XML
--USA CTE (WITH PAGOSORDENADOS)
--Crea una tabla temporal con fechadepagoactual y fechapagoanterior
--Calcula la diferencia en dias entre pago y pago
--Filtro: idconsorcio(solo pagos del consorcio especificado), iduf (solo pagos de la uf)
--fecha desde: solo pagos desde esa fecha
--Sirve para analizar la regularidad de pagos de una uf, detectar irregularidades (muchos dias entre pagos
--ver si un inquilino paga mensualmente, anualmente, etc.
--LAG WINDOWS FUNCTION que trae el valor de la fila anterior
--Lag "mirar hacia atras", devuelve el pagoanterior a la fechapagoactual
