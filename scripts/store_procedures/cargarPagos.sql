CREATE PROCEDURE [dbo].[sp_importarPagos]
    @RutaArchivoCSV NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
   
    DECLARE @BulkInsertSQL NVARCHAR(MAX);
	DECLARE @ExisteArchivo INT;

    EXEC master.dbo.xp_fileexist @RutaArchivoCSV, @ExisteArchivo OUTPUT;

    IF @ExisteArchivo = 0
    BEGIN
        PRINT 'ERROR: El archivo no existe en la ruta especificada: ' + @RutaArchivoCSV;
        RETURN;
    END

    PRINT 'Archivo encontrado: ' + @RutaArchivoCSV;

    DROP TABLE IF EXISTS #pago_staging;

    CREATE TABLE #pago_staging (
        id_pago_csv VARCHAR(10),
        fecha_csv varchar(10),
        cvu_cbu_csv varchar(22),
        valor_csv varchar(20)
    );

    SET @BulkInsertSQL = 
        N'BULK INSERT #pago_staging ' +
        N'FROM ''' + @RutaArchivoCSV + N''' ' + 
        N'WITH ( ' +
        N'    FIELDTERMINATOR = '','', ' +
        N'    ROWTERMINATOR = ''\n'', ' +
        N'    FIRSTROW = 2, ' +
        N'    CODEPAGE = ''ACP'' ' +
        N');';

    BEGIN TRY
        EXECUTE sp_executesql @BulkInsertSQL;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
        PRINT 'ERROR en BULK INSERT: ' + @ErrorMessage;
        RETURN;
    END CATCH

    INSERT INTO dbo.pago (
        id_pago,
        fecha,
        cuenta,
        importe
    )
    SELECT
        id_pago_csv,
        CONVERT(DATE, fecha_csv, 103),
        cvu_cbu_csv,
        dbo.corregirValor(valor_csv)
    FROM
        #pago_staging
    WHERE id_pago_csv IS NOT NULL;

    DECLARE @FilasInsertadas INT = @@ROWCOUNT;
    PRINT 'Proceso de importación completado. Filas insertadas en dbo.pago: ' + CAST(@FilasInsertadas AS VARCHAR(10));
END

create function corregirValor(@valor varchar(20))
returns decimal(10,2)
as
begin
	DECLARE @resultado DECIMAL(10,2);
	DECLARE @limpio VARCHAR(50);

	SET @limpio = REPLACE(@valor, '$', '');
	SET @limpio = LTRIM(RTRIM(@limpio));

	IF CHARINDEX(',', @limpio) > 0
	BEGIN
		SET @limpio = REPLACE(@limpio, '.', '');
		SET @limpio = REPLACE(@limpio, ',', '.');
	END
	ELSE
	BEGIN
		SET @limpio = REPLACE(@limpio, '.', '');
	END


	SET @resultado = TRY_CAST(@limpio AS DECIMAL(10,2));

	RETURN @resultado;
end
