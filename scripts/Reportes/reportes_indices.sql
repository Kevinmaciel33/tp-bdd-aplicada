-- ======================================
-- ÍNDICES PARA OPTIMIZAR REPORTES
-- ======================================

-- Reportes 1, 2, 4 y 6: accesos por fecha de pago
CREATE INDEX IX_Pago_FechaPago 
    ON tpo.Pago(FechaPago);
GO

-- Reportes 1, 2, 3, 4, 6: filtrar por consorcio
CREATE INDEX IX_Expensa_IdConsorcio 
    ON tpo.Expensa(IdConsorcio);
GO

-- Reportes 2, 3, 4, 6: joins por IdExpensa
CREATE INDEX IX_DetalleExpensa_IdExpensa
    ON tpo.DetalleExpensa(IdExpensa);
GO

-- Reportes 1, 2, 5, 6: joins por IdDetalleExp
CREATE INDEX IX_Pago_IdDetalleExp
    ON tpo.Pago(IdDetalleExp);
GO

-- Reportes 2, 5, 6: búsquedas por IdUf
CREATE INDEX IX_DetalleExpensa_IdUf
    ON tpo.DetalleExpensa(IdUf);
GO

-- Reporte 5: propietarios
CREATE INDEX IX_UnidadFuncional_IdPropietario
    ON tpo.UnidadFuncional(IdPropietario);
GO

-- Reporte 4 (gastos): por mes en FACTURA
CREATE INDEX IX_Factura_Mes
    ON tpo.Factura(Mes);
GO
CREATE INDEX IX_Factura_IdExpensa
    ON tpo.Factura(IdExpensa);
GO

-- Reporte 6: filtro + ordenamiento por fecha para cada UF
CREATE INDEX IX_DetalleExpensa_IdUf_Fecha
    ON tpo.DetalleExpensa(IdUf);
GO



