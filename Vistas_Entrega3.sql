------VISTAS ENTREGA 3 --------
CREATE OR ALTER VIEW vw_VentasPorCategoria
AS
SELECT
    dp.ProductCategory,
    dp.ProductCategoryEN,

    COUNT(DISTINCT fs.OrderID) AS TotalOrdenes,

    SUM(fs.Quantity) AS UnidadesVendidas,

    SUM(fs.SalesAmount) AS VentasTotales,

    AVG(fs.SalesAmount) AS TicketPromedioProducto,

    AVG(fs.ReviewScore) AS CalificacionPromedio

FROM FactSales fs
INNER JOIN DimProduct dp
    ON fs.ProductKey = dp.ProductKey
GROUP BY
    dp.ProductCategory,
    dp.ProductCategoryEN;
GO

----------------------------------
CREATE OR ALTER VIEW vw_ClientesFrecuentes
AS
SELECT
    dc.CustomerUniqueID,

    COUNT(DISTINCT fs.OrderID) AS TotalCompras,

    SUM(fs.SalesAmount) AS TotalGastado,

    AVG(fs.SalesAmount) AS TicketPromedio,

    MAX(dd.FullDate) AS FechaUltimaCompra,

    CASE
        WHEN COUNT(DISTINCT fs.OrderID) >= 10
            THEN 'VIP'
        WHEN COUNT(DISTINCT fs.OrderID) >= 5
            THEN 'Frecuente'
        ELSE 'Recurrente'
    END AS SegmentoCliente

FROM FactSales fs
INNER JOIN DimCustomer dc
    ON fs.CustomerKey = dc.CustomerKey
INNER JOIN DimDate dd
    ON fs.DateKey = dd.DateKey

GROUP BY
    dc.CustomerUniqueID

HAVING COUNT(DISTINCT fs.OrderID) > 1;
GO

------------------------------------------------------

CREATE OR ALTER VIEW vw_ResumenEjecutivoMensual
AS

WITH VentasMes AS
(
    SELECT
        dd.YearNumber AS Anio,
        dd.MonthNumber AS Mes,
        dd.MonthName AS NombreMes,

        SUM(fs.SalesAmount) AS VentasTotales,

        COUNT(DISTINCT fs.OrderID) AS CantidadOrdenes,

        COUNT(DISTINCT fs.CustomerKey) AS ClientesActivos,

        ROUND(
            SUM(fs.SalesAmount) * 1.0 /
            COUNT(DISTINCT fs.OrderID),
            2
        ) AS TicketPromedio

    FROM FactSales fs
    INNER JOIN DimDate dd
        ON fs.DateKey = dd.DateKey

    GROUP BY
        dd.YearNumber,
        dd.MonthNumber,
        dd.MonthName
)

SELECT

    vm.Anio,
    vm.Mes,
    vm.NombreMes,

    vm.VentasTotales,

    vm.CantidadOrdenes,

    vm.ClientesActivos,

    vm.TicketPromedio,

    (
        SELECT TOP 1
            dp.ProductCategoryEN
        FROM FactSales fs
        INNER JOIN DimProduct dp
            ON fs.ProductKey = dp.ProductKey
        INNER JOIN DimDate dd
            ON fs.DateKey = dd.DateKey
        WHERE dd.YearNumber = vm.Anio
        AND dd.MonthNumber = vm.Mes
        GROUP BY dp.ProductCategoryEN
        ORDER BY SUM(fs.SalesAmount) DESC
    ) AS CategoriaLider,

    (
        SELECT TOP 1
            dp.ProductCategoryEN
        FROM FactSales fs
        INNER JOIN DimProduct dp
            ON fs.ProductKey = dp.ProductKey
        INNER JOIN DimOrderStatus dos
            ON fs.OrderStatusKey = dos.OrderStatusKey
        INNER JOIN DimDate dd
            ON fs.DateKey = dd.DateKey
        WHERE dos.OrderStatus = 'canceled'
          AND dd.YearNumber = vm.Anio
          AND dd.MonthNumber = vm.Mes
        GROUP BY dp.ProductCategoryEN
        ORDER BY COUNT(*) DESC
    ) AS CategoriaMayorDevolucion

FROM VentasMes vm;
GO