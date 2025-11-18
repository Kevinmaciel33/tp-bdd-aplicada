CREATE OR ALTER PROCEDURE [tpo].[sp_cargarGastosExt]
    @RutaJSON NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @Json NVARCHAR(MAX);

    SET @sql = '
        SELECT @Json_OUT = BulkColumn
        FROM OPENROWSET(
            BULK ''' + @RutaJSON + ''',
            SINGLE_CLOB
        ) AS j;
    ';

    EXEC sp_executesql
        @sql,
        N'@Json_OUT NVARCHAR(MAX) OUTPUT',
        @Json_OUT=@Json OUTPUT;

    INSERT INTO tpo.Factura (NombreConsorcio, Mes, Detalle, Importe, EnCuotas, Tipo)
    SELECT
        c.IdConsorcio as NombreConsorcio,
        UPPER(TRIM(JSON_VALUE(j.value, '$.Mes'))) AS Mes,
        JSON_VALUE(j.value, '$.Detalle') AS Detalle,
        TRY_CAST(JSON_VALUE(j.value, '$.Importe') AS DECIMAL(12,2)) AS Importe,
        0 AS EnCuotas,
        'E' AS Tipo
    FROM OPENJSON(@Json) j
    INNER JOIN tpo.Consorcio c
        ON c.Nombre = JSON_VALUE(j.value, '$."Nombre del consorcio"');
END;
GO
