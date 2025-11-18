---TP BDA
---Creacion de bd, esquemas, tablas y sp

IF NOT EXISTS ( SELECT name FROM sys.databases WHERE name = 'Com2900G10')
BEGIN
    PRINT 'Creando la base de datos Com2900G10...';
    CREATE DATABASE Com2900G10
    COLLATE Modern_Spanish_CI_AS; -- Latin1_General_CI_AI;
END
ELSE
BEGIN
    PRINT 'La base de datos Com2900G10 ya existe.';
END
GO

use Com2900G10
go

--verifica si existe el esquema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'tpo')
BEGIN
	EXEC('CREATE SCHEMA tpo')
END
GO


--:WHENEVER SQLERROR EXIT -1 
--ACTIVAR 'SQLCMD Mode' desde la opcion "Query" en la barra
PRINT 'Ejecutando script de TABLAS...';
:r "C:\tp-bdd-aplicada\scripts\tablas\creacionTablas.sql"
PRINT '...Tablas creadas.';
GO 

--CREAMOS LAS CLAVES DE ENCRIPTADO
PRINT 'Creando la clave de cifrado...';
go
:r "C:\tp-bdd-aplicada\scripts\store_procedures\cargarClaveEncriptado.sql"

--CREAMOS LOS TRIGGER
PRINT 'Creando Triggers...';
go
:r "C:\tp-bdd-aplicada\scripts\triggers\cifrarDatosPersonales.sql"
PRINT '...Triggers creados.';
GO 

--CREAMOS LOS SP
PRINT 'Creando Stored Procedures...';
go
:r "C:\tp-bdd-aplicada\scripts\store_procedures\cargarTipoPersona.sql"
go
:r "C:\tp-bdd-aplicada\scripts\store_procedures\cargarInquilinoPropietario.sql"
go
:r "C:\tp-bdd-aplicada\scripts\store_procedures\cargarConsorcios.sql"
go
:r "C:\tp-bdd-aplicada\scripts\store_procedures\cargarUnidadesFuncionales.sql"
go
:r "C:\tp-bdd-aplicada\scripts\store_procedures\cargarProveedores.sql"
go
:r "C:\tp-bdd-aplicada\scripts\store_procedures\cargarPagos.sql"
go
:r "C:\tp-bdd-aplicada\scripts\store_procedures\cargarGastos.sql"
go
:r "C:\tp-bdd-aplicada\scripts\store_procedures\cargarInquilino-PropietarioUF.sql"
go
:r "C:\tp-bdd-aplicada\scripts\store_procedures\asociarPagos.sql"
go
:r "C:\tp-bdd-aplicada\scripts\store_procedures\pruebaGenerarExpensa.sql"
go
PRINT '...Stored Procedures creados.';
GO

PRINT 'Iniciando carga de DATOS...';
go
BEGIN TRANSACTION CargaDatos;

BEGIN TRY
    -- Paso 0
    PRINT 'Cargando TipoPersona...';
    EXEC tpo.sp_cargarTipoPersona @IdTipo = '0', @Descripcion = 'P';
    EXEC tpo.sp_cargarTipoPersona @IdTipo = '1', @Descripcion = 'I';
    PRINT '... TipoPersona cargados.';
    -- Paso 1

    PRINT 'Cargando Inquilinos/Propietarios...';
    EXEC tpo.sp_cargarInquilinoPropietario 'C:\tp-bdd-aplicada\archivos_a_importar\Inquilino-propietarios-datos.csv';
    PRINT '... Inquilinos/Propietarios cargados.';

    -- Paso 2
    PRINT 'Importando Consorcios...';
    EXEC tpo.sp_importarConsorcios 'C:\tp-bdd-aplicada\archivos_a_importar\Datos varios - Consorcios.csv';
    PRINT '... Consorcios importados.';

    -- Paso 3
    PRINT 'Cargando Unidades Funcionales...';
    EXEC tpo.sp_cargarUnidadesFuncionales 'C:\tp-bdd-aplicada\archivos_a_importar\UF por consorcio.txt';
    PRINT '... Unidades Funcionales cargadas.';

    -- Paso 4
    PRINT 'Cargando Proveedores...';
    EXEC tpo.sp_cargarProveedores 'C:\tp-bdd-aplicada\archivos_a_importar\Datos varios - Proveedores.csv';
    PRINT '... Proveedores cargados.';

    -- Paso 5
    PRINT 'Importando Pagos...';
    EXEC tpo.sp_importarPagos 'C:\tp-bdd-aplicada\archivos_a_importar\pagos_consorcios.csv';
    PRINT '... Pagos importados.';

    -- Paso 6
    PRINT 'Cargando Gastos Ordinarios...';
    EXEC tpo.sp_cargarGastos 'C:\tp-bdd-aplicada\archivos_a_importar\Servicios.Servicios.json';
    PRINT '... Gastos Ordinarios cargados.';

    -- Paso 7
    PRINT 'Agregando Cuentas UF...';
    EXEC tpo.sp_agregarCuentasUF 'C:\tp-bdd-aplicada\archivos_a_importar\Inquilino-propietarios-UF.csv';
    PRINT '... Cuentas UF agregadas.';

	PRINT 'Asociando pagos...';
    EXEC tpo.sp_asociarPagos;
    PRINT '... pagos asociados.';

    COMMIT TRANSACTION CargaDatos;
    
    PRINT '==================================================';
    PRINT 'Todos los datos fueron cargados correctamente.';
    PRINT '==================================================';

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION CargaDatos;

    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    PRINT '¡ERROR! El script ha fallado.';
    PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    PRINT 'El último paso que se intentó ejecutar fue: (Ver mensaje anterior a este bloque)';
    PRINT ' ';
    PRINT 'Mensaje de Error: ' + ERROR_MESSAGE();
    PRINT 'Número de Error:  ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT 'Línea del Error:  ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT 'Procedimiento:    ' + ISNULL(ERROR_PROCEDURE(), 'No estaba dentro de un SP (falló el script principal)');
    PRINT ' ';
    PRINT 'Todos los cambios han sido revertidos (ROLLBACK).';
    PRINT 'La base de datos está limpia.';

END CATCH
GO
-----GENERAR EXPENSA-----

BEGIN TRANSACTION CargaExpensa;
BEGIN TRY
	EXEC tpo.sp_generarExpensa 6,2025,1 ---Mes de la expensa q se quiere generar, año, id del consorcio
	PRINT 'TODO OK'
	COMMIT TRANSACTION CargaExpensa;
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION CargaExpensa;
	print 'ERROR: ' + error_message();
END CATCH
GO

PRINT 'Creando Reportes...';
GO
:r "C:\tp-bdd-aplicada\scripts\reportes\reportes.sql"
GO
PRINT '...Reportes creados.';
GO

PRINT 'Creando índices de reportes...';
GO
:r "C:\tp-bdd-aplicada\scripts\reportes\reportes_indices.sql"
GO
PRINT '...Índices creados.';
GO

PRINT 'Ejecución de reportes...';
GO
:r "C:\tp-bdd-aplicada\scripts\reportes\reportes_ejecucion.sql"
GO
PRINT '==================================================';
PRINT 'Reportes ejecutados correctamente.';
PRINT '==================================================';
GO

PRINT 'Creando API de cotización del dólar...';
GO
:r "C:\tp-bdd-aplicada\scripts\reportes\API_dolar.sql"
GO
PRINT '...API creada correctamente.';
GO

PRINT 'Ejecutando API de cotización del dólar...';
GO
EXEC tpo.sp_actualizar_cotizacion_dolar;
GO
SELECT * FROM tpo.cotizacion_dolar;
GO
PRINT '...Cotización del dólar actualizada y registrada.';
GO

--CREAMOS LOS ROLES
PRINT 'Creando los roles y permisos...';
go
:r "C:\tp-bdd-aplicada\scripts\roles_permisos\permisos.sql"
