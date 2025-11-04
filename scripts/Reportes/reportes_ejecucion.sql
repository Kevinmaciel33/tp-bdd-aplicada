--INVOCACIÓN A LOS SP DE REPORTES

-- Reporte 1
EXEC tpo.sp_reporte_flujo_caja '2025-01-01', '2025-12-31', 1;
GO

-- Reporte 2
EXEC tpo.sp_reporte_recaudacion_mensual 2025, 1;
GO

-- Reporte 3
EXEC tpo.sp_reporte_recaudacion_desA '2025-01-01', '2025-12-31', 1;

-- Reporte 4
EXEC tpo.sp_reporte_top5_gastos_ingresos 1;
GO

-- Reporte 5
EXEC tpo.sp_reporte_top3_morosidad;
GO

-- Reporte 6
EXEC tpo.sp_reporte_dias_entre_pagos 1, 1, '2025-01-01';
GO

