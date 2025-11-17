CREATE OR ALTER PROCEDURE tpo.sp_cargarTipoPersona
    @IdTipo CHAR(1),
    @Descripcion CHAR(12)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verifica si el ID ya existe para decidir si inserta o actualiza
    IF EXISTS (SELECT 1 FROM tpo.TipoPersona WHERE IdTipo = @IdTipo)
    BEGIN
        UPDATE tpo.TipoPersona
        SET Descripcion = @Descripcion
        WHERE IdTipo = @IdTipo;
    END
    ELSE
    BEGIN
        INSERT INTO tpo.TipoPersona (IdTipo, Descripcion)
        VALUES (@IdTipo, @Descripcion);
    END
END
GO