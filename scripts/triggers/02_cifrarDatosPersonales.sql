/*
Este trigger se ejecuta en lugar del INSERT sobre la tabla `tpo.Persona` y se encarga de cifrar automáticamente los datos personales sensibles antes de guardarlos en la base de datos.
18/11/2025
Com2900G10
Grupo 10
Bases de datos aplicadas
Integrantes:
-Kevin Maciel
-Marcos kouvach
-Agostina salas
-Keila Álvarez Da Silva*/
DROP TRIGGER IF EXISTS [tpo].[cifrarDatosPersonales];
GO

CREATE OR ALTER TRIGGER [tpo].[cifrarDatosPersonales]
ON [tpo].[Persona]
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    OPEN SYMMETRIC KEY ClaveTP
    DECRYPTION BY CERTIFICATE CertificadoTP;

    INSERT INTO tpo.Persona (
        DNI,
        Nombre,
        Apellido,
        Email,
        Telefono,
        Cuenta,
        IdTipo
    )
    SELECT
        I.DNI,
        EncryptByKey(Key_GUID('ClaveTP'), CONVERT(VARCHAR(MAX), I.Nombre)),
        EncryptByKey(Key_GUID('ClaveTP'), CONVERT(VARCHAR(MAX), I.Apellido)),
        EncryptByKey(Key_GUID('ClaveTP'), CONVERT(VARCHAR(MAX), I.Email)),
        EncryptByKey(Key_GUID('ClaveTP'), CONVERT(VARCHAR(MAX), I.Telefono)),
        EncryptByKey(Key_GUID('ClaveTP'), CONVERT(VARCHAR(MAX), I.Cuenta)),
        I.IdTipo
    FROM
        inserted AS I;

    CLOSE SYMMETRIC KEY ClaveTP;
END;
