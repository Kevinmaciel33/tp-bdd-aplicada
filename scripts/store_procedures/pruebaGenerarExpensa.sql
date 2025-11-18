GO
DROP FUNCTION IF EXISTS tpo.f_obtenerQuintoDiaHabil;
GO
DROP FUNCTION IF EXISTS tpo.f_mesANumero;
GO
CREATE FUNCTION [tpo].[f_obtenerQuintoDiaHabil]
(
    @Anio INT,
    @Mes INT
)
RETURNS DATE
AS
BEGIN
    DECLARE @Fecha DATE;
    DECLARE @DiaHabilContador INT = 0;
    DECLARE @FechaActual DATE;
    
    SET @FechaActual = DATEFROMPARTS(@Anio, @Mes, 1);
    
    WHILE @DiaHabilContador < 5
    BEGIN
        IF MONTH(@FechaActual) != @Mes
        BEGIN
            RETURN NULL; 
        END

        IF DATEPART(dw, @FechaActual) NOT IN (1, 7)
        BEGIN
            SET @DiaHabilContador = @DiaHabilContador + 1;
        END

        IF @DiaHabilContador = 5
        BEGIN
            SET @Fecha = @FechaActual;
            BREAK;
        END

        SET @FechaActual = DATEADD(day, 1, @FechaActual);
    END
    
    RETURN @Fecha;
END
GO
CREATE FUNCTION [tpo].[f_mesANumero]
	(@Mes varchar(10))
RETURNS INT
AS
begin
	DECLARE @NumeroMes INT;
    SET @Mes = LOWER(TRIM(@Mes)); 
    
    SET @NumeroMes = CASE @Mes
        WHEN 'enero' THEN 1
        WHEN 'febrero' THEN 2
        WHEN 'marzo' THEN 3
        WHEN 'abril' THEN 4
        WHEN 'mayo' THEN 5
        WHEN 'junio' THEN 6
        WHEN 'julio' THEN 7
        WHEN 'agosto' THEN 8
        WHEN 'septiembre' THEN 9
        WHEN 'octubre' THEN 10
        WHEN 'noviembre' THEN 11
        WHEN 'diciembre' THEN 12
        ELSE NULL -- Devuelve NULL si el nombre no coincide
    END;
    
    RETURN @NumeroMes;
end

go
CREATE OR ALTER PROCEDURE [tpo].[sp_generarExpensa]
	@Mes int, @Anio int, @IdConsorcio int
as
begin
	set nocount on;
	--DATOS DE EXPENSA MAYO (FECHAS)
	DECLARE @FechaGeneracion DATE = tpo.f_obtenerQuintoDiaHabil(@Anio,@Mes); --QUINTO DIA HABIL--ejemplo: 5/5/2025
	DECLARE @FechaVTO1 DATE = DATEADD(day,5,@FechaGeneracion); --5 DIAS DESPUES DE LA GENERACION--ejemplo: 10/5/2025
	DECLARE @FechaVTO2 DATE = DATEADD(day,5,@FechaVTO1); --VTO1 + 5 DIAS--ejemplo: 15/5/2025

	--DATOS ABRIL, VTO1, VTO2....
	DECLARE @MesAnterior INT = @Mes - 1
	DECLARE @vto1MesAnterior DATE = (select top 1 e.vto1 from tpo.Expensa e where e.Mes = (@Mes - 1))
	DECLARE @FechaGenMesAnterior DATE = (select top 1 e.FechaGeneracion from tpo.Expensa e where e.Mes = (@Mes - 1))
	DECLARE @TotalOrd DECIMAL(10,2);
	DECLARE @TotalExt DECIMAL(10,2);
	SET @TotalOrd = ISNULL(
						(select SUM(f.Importe) from tpo.Factura f
						INNER JOIN tpo.Consorcio c on c.IdConsorcio = f.NombreConsorcio
						WHERE f.Tipo = 'O' AND tpo.f_mesANumero(f.Mes)=@MesAnterior
						AND c.IdConsorcio=@IdConsorcio)
						,0.00); --suma de los gastos ord de abril
	SET @TotalExt = ISNULL((select SUM(f.Importe) from tpo.Factura f
						INNER JOIN tpo.Consorcio c on  c.IdConsorcio = f.NombreConsorcio
						WHERE f.Tipo = 'E' AND tpo.f_mesANumero(f.Mes)=@MesAnterior
						AND c.IdConsorcio=@IdConsorcio)
						,0.00); -- suma de los gastos ext de abril

	BEGIN TRY
	PRINT 'Comenzando proceso de generacion expensa para mes: ' + CAST(@Mes AS VARCHAR(2));
	
	DECLARE @SaldoAnterior DECIMAL(10,2) = ISNULL((select e.SaldoCierre from tpo.Expensa e where e.Mes = (@Mes-1) AND e.IdConsorcio = @IdConsorcio),0.00); -- 0 en este caso
	DECLARE @IngresosEnTermino DECIMAL(10,2) = ISNULL((select SUM(p.Importe) from tpo.Pago p
								INNER JOIN tpo.UnidadFuncional uf on uf.IdUf=p.IdUf  --la uf debe ser parte del consorcio que estamos analizando
								where uf.IdConsorcio=@IdConsorcio 
								AND p.FechaPago <= @vto1MesAnterior 
								AND p.FechaPago >= @FechaGenMesAnterior ),0.00); --Suma de todos los pagos de ABRIL que se recibieron antes del VTO 1 de MARZO (la expensa anterior).
	DECLARE @IngresosAdeudados DECIMAL(10,2) = ISNULL((select SUM(p.Importe) from tpo.Pago p
								INNER JOIN tpo.UnidadFuncional uf on uf.IdUf=p.IdUf  --la uf debe ser parte del consorcio que estamos analizando
								where uf.IdConsorcio=@IdConsorcio 
								AND p.FechaPago > @vto1MesAnterior 
								AND p.FechaPago <= @FechaGeneracion),0.00); --ingresos despues del VTO1
	DECLARE @IngresosAdelantados DECIMAL(10,2) = ISNULL((select SUM(p.Importe) from tpo.Pago p
								INNER JOIN tpo.UnidadFuncional uf on uf.IdUf=p.IdUf  --la uf debe ser parte del consorcio que estamos analizando
								where uf.IdConsorcio=@IdConsorcio 
								AND p.FechaPago >= @FechaGenMesAnterior 
								AND p.FechaPago < @FechaGeneracion),0.00);
	
	DECLARE @Egresos DECIMAL(10,2);
	DECLARE @TotalPagosRecibidos DECIMAL(10,2); --suma de todos los pagos de las UF
	DECLARE @SaldoCierre DECIMAL(10,2); --(Saldo anterior + Ingresos) - Egresos, ES DE TODAS LAS UF
	
	SET @Egresos = @TotalOrd + @TotalExt
	SET @TotalPagosRecibidos = @IngresosAdelantados + @IngresosAdeudados + @IngresosEnTermino
	SET @SaldoCierre = (@SaldoAnterior + @TotalPagosRecibidos) - @Egresos

	INSERT INTO tpo.Expensa (IdConsorcio,Mes,FechaGeneracion,vto1,vto2,SaldoAnterior,IngresosPagoTermino,IngresosPagoAdeudado,
					IngresosPagoAdelantado,Egresos,SaldoCierre)
	VALUES (@IdConsorcio,@Mes,@FechaGeneracion,@FechaVTO1,@FechaVTO2,@SaldoAnterior,@IngresosEnTermino,@IngresosAdeudados,
			@IngresosAdelantados,@Egresos,@SaldoCierre)
	
	PRINT 'Expensa del consorcio: ' + CAST(@IdConsorcio AS VARCHAR(10)) + ' generada correctamente para mes: ' + CAST(@Mes AS VARCHAR(2));

	END TRY
	BEGIN CATCH
		PRINT 'Mensaje de Error de Expensa: ' + ERROR_MESSAGE();
		return -1
	END CATCH
	----------GENERAR CSV CON LOS DATOS---------------

	--------------------------------------------------
	----------ESTADO DE CUENTAS Y PRORRATEO-----------
	--------------------------------------------------
	--esto deberia repetirse para cada unidad funcional que sea parte del consorcio
	BEGIN TRY
	PRINT 'Proceso detalle expensa'
	DECLARE @M2Consorcio DECIMAL(18,6) = (SELECT c.M2total FROM tpo.Consorcio c WHERE c.IdConsorcio=@IdConsorcio);

	--HAY QUE BUSCAR EL ID DE LA EXPENSA QUE SE ACABA DE GENERAR
	DECLARE @IdExpensa INT = (select e.IdExpensa from tpo.Expensa e where e.Mes = @Mes); ---expensa del mes que elegimos crear
	SET @FechaGenMesAnterior =  tpo.f_obtenerQuintoDiaHabil(@Anio,@MesAnterior);
	SET @FechaVTO1 = DATEADD(day,5,@FechaGeneracion);
	SET @FechaVTO2 = DATEADD(day,5,@FechaVTO1);


	--CALCULOS POR CADA UNIDAD FUNCIONAL
	----COMENZAR LA LOGICA PARA EL PRORRATEO
	WITH PagosUf AS (--AGREGAR A LA TABLA PAGOS EL CONSORCIO CUANDO HAGA LA ASOCIACION DE PAGOS
		SELECT --PAGOS RECIBIDOS ABRIL
			p.IdUf,
			SUM(case when p.FechaPago <= @FechaVTO1 then p.Importe else 0 end) as Pagos_AntesVto1,
			SUM(case when p.FechaPago > @FechaVTO1 and p.FechaPago <= @FechaVTO2 then p.Importe else 0 end) as Pagos_EntreVto1Vto2,
			SUM(case when p.FechaPago > @FechaVTO2 and p.FechaPago <= @FechaGeneracion then p.Importe else 0 end) as Pagos_DespuesVto2,
			SUM(case when p.FechaPago > @FechaGenMesAnterior and p.FechaPago <= @FechaGeneracion then p.Importe else 0 end) as Pagos_Totales
		FROM tpo.Pago p
		WHERE p.IdUf IS NOT NULL
          AND p.FechaPago >= @FechaGenMesAnterior
          AND p.FechaPago <= @FechaGeneracion
          AND EXISTS (SELECT 1 FROM tpo.UnidadFuncional uf WHERE uf.IdUf = p.IdUf AND uf.IdConsorcio = @IdConsorcio)
        GROUP BY p.IdUf
	),
	UnidadFuncional AS (
		SELECT
			uf.IdUf,
			uf.M2,
			uf.IdConsorcio,
			ISNULL(SUM(ee.M2EspacioExtra),0) as TotalExtra,
			(uf.M2 + ISNULL(SUM(ee.M2EspacioExtra),0)) AS TotalM2
		FROM tpo.UnidadFuncional uf
		LEFT JOIN tpo.EspacioExtra ee on ee.IdUf=uf.IdUf
		WHERE uf.IdConsorcio = @IdConsorcio
		GROUP BY uf.IdUf, uf.IdConsorcio, uf.M2
	),
	SaldoAnterior AS (
		SELECT
			de.IdUf,
			ISNULL(de.Deuda,0) AS DeudaAnterior 
		FROM tpo.DetalleExpensa de 
		INNER JOIN tpo.Expensa e on e.IdExpensa=de.IdExpensa
		WHERE e.Mes=@MesAnterior AND e.IdConsorcio = @IdConsorcio
	)

	insert into tpo.DetalleExpensa (
			IdExpensa,
			IdUf,
			Porcentaje, --(SUM(uf.m2,(select a espacio extra))/@m2consorcio) * 100
			SaldoAnterior, --nullif, son los pagos antes de la generacion pero del mismo mes de la expensa actual
			PagosRecibidos, --select de la tabla pago por CBU
			Deuda,--(GASTOS ORD Y EXT + SaldoAnterior) - Pagos recibidos
			InteresesMora,
			TotalOrd, --lo sacamos de expensa y calculamos segun porcentaje
			TotalExt,
			Total
			)
	select @IdExpensa AS IdExpensa,
			u.IdUf,
			CAST((CAST(u.TotalM2 AS DECIMAL(18,6)) / NULLIF(CAST(@M2Consorcio AS DECIMAL(18,6)),0)) * 100
			AS DECIMAL(5,2)) AS Porcentaje,
			ISNULL(de.DeudaAnterior,0) AS SaldoAnterior,
			ISNULL(p.Pagos_Totales,0) AS PagosRecibidos,
			(ISNULL(de.DeudaAnterior,0) - ISNULL(p.Pagos_Totales,0)) AS Deuda,
			CASE 
				WHEN ISNULL(de.DeudaAnterior,0)<= 0 then 0
				WHEN ISNULL(p.Pagos_EntreVto1Vto2,0) >= ISNULL(de.DeudaAnterior,0) then (ISNULL(de.DeudaAnterior,0) * 0.02)
				WHEN ISNULL(p.Pagos_DespuesVto2,0) >= ISNULL(de.DeudaAnterior,0) then (ISNULL(de.DeudaAnterior,0) * 0.05)
				else ISNULL(de.DeudaAnterior,0)*0.05
			END AS InteresMora,
			CAST(
				@TotalOrd *
				(CAST(u.TotalM2 AS DECIMAL(18,6)) / NULLIF(CAST(@M2Consorcio AS DECIMAL(18,6)),0))
			AS DECIMAL(12,2)) AS TotalOrd
			,
			CAST(
				@TotalExt *
				(CAST(u.TotalM2 AS DECIMAL(18,6)) / NULLIF(CAST(@M2Consorcio AS DECIMAL(18,6)),0))
			AS DECIMAL(12,2)) AS TotalExt
			,
			CAST(
			(
				@TotalOrd *
				(CAST(u.TotalM2 AS DECIMAL(18,6)) / NULLIF(CAST(@M2Consorcio AS DECIMAL(18,6)),0))
				+
				@TotalExt *
				(CAST(u.TotalM2 AS DECIMAL(18,6)) / NULLIF(CAST(@M2Consorcio AS DECIMAL(18,6)),0))
				+
				CASE 
					WHEN ISNULL(de.DeudaAnterior,0)<= 0 then 0
					WHEN ISNULL(p.Pagos_EntreVto1Vto2,0) >= ISNULL(de.DeudaAnterior,0) then de.DeudaAnterior * 0.02
					WHEN ISNULL(p.Pagos_DespuesVto2,0) >= ISNULL(de.DeudaAnterior,0) then de.DeudaAnterior * 0.05
					else de.DeudaAnterior * 0.05
				END
			)
		AS DECIMAL(12,2)) AS Total
	from UnidadFuncional u
	LEFT JOIN PagosUf p on u.IdUf = p.IdUf
	LEFT JOIN SaldoAnterior de on de.IdUf=u.IdUf
	where u.IdConsorcio = @IdConsorcio

	PRINT 'DetalleExpensa generado. IdExpensa = ' + CAST(@IdExpensa AS VARCHAR(10));
	END TRY
	BEGIN CATCH
		PRINT 'Mensaje de error DetalleExpensa: ' + ERROR_MESSAGE();
		PRINT 'Número de Error:  ' + CAST(ERROR_NUMBER() AS VARCHAR);
		PRINT 'Línea del Error:  ' + CAST(ERROR_LINE() AS VARCHAR);
		PRINT 'Procedimiento:    ' + ISNULL(ERROR_PROCEDURE(), 'No estaba dentro de un SP (falló el script principal)');
		return -1;
	END CATCH
    SET NOCOUNT OFF;
	
end
go
