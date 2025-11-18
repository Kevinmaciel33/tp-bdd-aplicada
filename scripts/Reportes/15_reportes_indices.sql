-- ÍNDICES PARA OPTIMIZAR REPORTES
-- Reportes 1, 2, 4 y 6: accesos por fecha de pago
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Pago_FechaPago' 
      AND object_id = OBJECT_ID('tpo.Pago')
)
BEGIN
    CREATE INDEX IX_Pago_FechaPago ON tpo.Pago(FechaPago);
END
GO

-- Reportes 1, 2, 3, 4, 6: filtrar por consorcio
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Expensa_IdConsorcio' 
      AND object_id = OBJECT_ID('tpo.Expensa')
)
BEGIN
    CREATE INDEX IX_Expensa_IdConsorcio ON tpo.Expensa(IdConsorcio);
END
GO

-- Reportes 2, 3, 4, 6: joins por IdExpensa
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_DetalleExpensa_IdExpensa' 
      AND object_id = OBJECT_ID('tpo.DetalleExpensa')
)
BEGIN
    CREATE INDEX IX_DetalleExpensa_IdExpensa ON tpo.DetalleExpensa(IdExpensa);
END
GO


-- Reportes 1, 2, 5, 6: joins por IdDetalleExp
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Pago_IdDetalleExp' 
      AND object_id = OBJECT_ID('tpo.Pago')
)
BEGIN
    CREATE INDEX IX_Pago_IdDetalleExp ON tpo.Pago(IdDetalleExp);
END
GO


-- Reportes 2, 5, 6: búsquedas por IdUf
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_DetalleExpensa_IdUf' 
      AND object_id = OBJECT_ID('tpo.DetalleExpensa')
)
BEGIN
    CREATE INDEX IX_DetalleExpensa_IdUf ON tpo.DetalleExpensa(IdUf);
END
GO

-- Reporte 5: propietarios
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_UnidadFuncional_Cuenta' 
      AND object_id = OBJECT_ID('tpo.UnidadFuncional')
)
BEGIN
    CREATE INDEX IX_UnidadFuncional_Cuenta ON tpo.UnidadFuncional(Cuenta);
END
GO


-- Reporte 4 (gastos): por mes en FACTURA
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Factura_Mes' 
      AND object_id = OBJECT_ID('tpo.Factura')
)
BEGIN
    CREATE INDEX IX_Factura_Mes ON tpo.Factura(Mes);
END
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Factura_IdExpensa' 
      AND object_id = OBJECT_ID('tpo.Factura')
)
BEGIN
    CREATE INDEX IX_Factura_IdExpensa ON tpo.Factura(IdExpensa);
END
GO


-- Reporte 6: filtro + ordenamiento por fecha para cada UF
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_DetalleExpensa_IdUf_Fecha' 
      AND object_id = OBJECT_ID('tpo.DetalleExpensa')
)
BEGIN
    CREATE INDEX IX_DetalleExpensa_IdUf_Fecha ON tpo.DetalleExpensa(IdUf);
END
GO





