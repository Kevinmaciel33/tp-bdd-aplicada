CREATE OR ALTER PROCEDURE [tpo].[sp_cargarGastos]
    @RutaArchivoJSON NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ExisteArchivo INT;
    EXEC master.dbo.xp_fileexist @RutaArchivoJSON, @ExisteArchivo OUTPUT;
    IF @ExisteArchivo = 0
    BEGIN
        PRINT 'ERROR: El archivo no existe en la ruta: ' + @RutaArchivoJSON;
        RETURN -1;
    END
  
    DECLARE @JsonContent NVARCHAR(MAX);
    DECLARE @SqlCmd NVARCHAR(MAX);
    
    SET @SqlCmd = N'
    SELECT @JsonContentOut = BulkColumn
    FROM OPENROWSET(BULK ''' + @RutaArchivoJSON + N''', SINGLE_CLOB) AS J;';

    BEGIN TRY
        EXEC sp_executesql @SqlCmd, N'@JsonContentOut NVARCHAR(MAX) OUTPUT', @JsonContent OUTPUT;
    END TRY
    BEGIN CATCH
        PRINT 'ERROR al leer el archivo JSON';
        PRINT ERROR_MESSAGE();
        --RETURN -1;
    END CATCH;

    BEGIN TRY
        INSERT INTO tpo.Factura (IdServicio, NombreConsorcio, Mes, Detalle, Importe, EnCuotas, Tipo) 
		SELECT	s.IdServicio, 
				c.IdConsorcio, 
				d.Mes,
				s.Nombre,
				tpo.corregirImportes(x.Importe) AS Importe,
				'0' as EnCuotas,
				'O' as Tipo
		FROM ( SELECT	TRIM(j.[Nombre del consorcio]) AS Consorcio, 
						TRIM(j.Mes) AS Mes, 
						j.BANCARIOS, 
						j.LIMPIEZA, 
						j.ADMINISTRACION, 
						j.SEGUROS, 
						j.[GASTOS GENERALES], 
						j.[SERVICIOS PUBLICOS-Agua], 
						j.[SERVICIOS PUBLICOS-Luz] 
			FROM OPENJSON(@JsonContent) 
			WITH ( [Nombre del consorcio] VARCHAR(100), 
					Mes VARCHAR(20), 
					BANCARIOS VARCHAR(50), 
					LIMPIEZA VARCHAR(50), 
					ADMINISTRACION VARCHAR(50), 
					SEGUROS VARCHAR(50), 
					[GASTOS GENERALES] VARCHAR(50), 
					[SERVICIOS PUBLICOS-Agua] VARCHAR(50), 
					[SERVICIOS PUBLICOS-Luz] VARCHAR(50) ) 
			AS j ) 
		AS d
		INNER JOIN tpo.Consorcio c ON c.Nombre = d.Consorcio 
		CROSS APPLY ( VALUES 
					('GASTOS BANCARIOS',null, d.BANCARIOS), 
					('GASTOS DE LIMPIEZA',null, d.LIMPIEZA), 
					('GASTOS DE ADMINISTRACION',null, d.ADMINISTRACION), 
					('SEGUROS',null, d.SEGUROS), 
					('GASTOS GENERALES',null, d.[GASTOS GENERALES]), 
					('SERVICIOS PUBLICOS','AYSA', d.[SERVICIOS PUBLICOS-Agua]), 
					('SERVICIOS PUBLICOS','EDENOR', d.[SERVICIOS PUBLICOS-Luz]) ) 
					AS x (CategoriaOriginal,Subcat, Importe) 
		
		LEFT JOIN tpo.Servicio s ON s.Categoria = x.CategoriaOriginal and c.Nombre=s.NombreConsorcio
		and (x.Subcat is null or s.Nombre like '%' + x.Subcat + '%')
		WHERE x.Importe IS NOT NULL and tpo.corregirImportes(x.Importe) <> 0;

        PRINT 'Proceso de carga a Factura completo. ' + CAST(@@ROWCOUNT AS VARCHAR) + ' filas en Factura.';
		UPDATE tpo.Factura
		SET Detalle = 'GASTOS GENERALES'
		WHERE Detalle IS NULL;

    END TRY
    BEGIN CATCH
        PRINT 'ERROR JSON.';
        PRINT ERROR_MESSAGE();
        RETURN -1;
    END CATCH;
    
    PRINT 'Proceso completado.';
    SET NOCOUNT OFF;
END
GO

CREATE or alter FUNCTION tpo.corregirImportes (@importeTexto VARCHAR(50))
RETURNS DECIMAL(10,2)
AS
	BEGIN
		DECLARE @Importe DECIMAL(10,2);
		DECLARE @decimal VARCHAR(2);
		SET @importeTexto = LTRIM(RTRIM(@importeTexto));
		SET @importeTexto = REPLACE(REPLACE(@importeTexto,',', ''),'.', '')
		SET @decimal = RIGHT(@importeTexto, 2)
		SET @importeTexto = LEFT(@importeTexto, len(@importeTexto)-2) 

		SET @Importe = TRY_CAST(@importeTexto+'.'+@decimal AS DECIMAL(18,2))

		RETURN @Importe;
END
GO
