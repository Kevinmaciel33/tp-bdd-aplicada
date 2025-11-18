/*
Este script crea los tipos de personas indicando 1 si es propietario o 0 si es inquilino.
18/11/2025
Com2900G10
Grupo 10
Bases de datos aplicadas
Integrantes:
-Kevin Maciel
-Marcos kouvach
-Agostina salas
-Keila Álvarez Da Silva*/
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
