--INDICES PARA OPTIMIZAR REPORTES

--Reporte 1 y 2: Búsqueda y agrupamiento por fecha de pago y consorcio
CREATE INDEX IX_Pago_FechaPago ON tpo.Pago(FechaPago);
GO
CREATE INDEX IX_Expensa_IdConsorcio ON tpo.Expensa(IdConsorcio);
GO

--Reporte 2 y 3: uso  de IdDetalleExp e IdExpensa en joins
CREATE INDEX IX_DetalleExpensa_IdExpensa ON tpo.DetalleExpensa(IdExpensa);
GO
CREATE INDEX IX_Pago_IdDetalleExp ON tpo.Pago(IdDetalleExp);
GO

--Reporte 4: Agrupación por mes en gastos ordinarios
CREATE INDEX IX_GastoOrdinario_Mes ON tpo.GastoOrdinario(Mes);
GO
CREATE INDEX IX_GastoOrdinario_IdConsorcio ON tpo.GastoOrdinario(IdConsorcio);
GO

--Reporte 5: Relación Persona - UnidadFuncional - Pagos
CREATE INDEX IX_Persona_DNI ON tpo.Persona(DNI);
GO
CREATE INDEX IX_UnidadFuncional_IdPropietario ON tpo.UnidadFuncional(IdPropietario);
GO
CREATE INDEX IX_UnidadFuncional_Cuenta ON tpo.UnidadFuncional(Cuenta);
GO
CREATE INDEX IX_Pago_IdUf ON tpo.Pago(IdUf);
GO

--Reporte 6: Días entre pagos (IdUf + FechaPago)
CREATE INDEX IX_Pago_IdUf_FechaPago ON tpo.Pago(IdUf, FechaPago);
GO

