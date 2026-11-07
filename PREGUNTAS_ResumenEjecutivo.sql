---- RESUMEN EJECUTIVO
--PREGUNTA 1---

WITH VentasCategoria AS
(
    SELECT
        dp.ProductCategoryEN,
        SUM(fs.SalesAmount) AS Ventas,
        AVG(fs.ReviewScore) AS CalificacionPromedio
    FROM FactSales fs
    INNER JOIN DimProduct dp
        ON fs.ProductKey = dp.ProductKey
    GROUP BY dp.ProductCategoryEN
),
Devoluciones AS
(
    SELECT
        dp.ProductCategoryEN,
        COUNT(*) AS TotalDevoluciones
    FROM FactSales fs
    INNER JOIN DimProduct dp
        ON fs.ProductKey = dp.ProductKey
    INNER JOIN DimOrderStatus dos
        ON fs.OrderStatusKey = dos.OrderStatusKey
    WHERE dos.OrderStatus = 'canceled'
    GROUP BY dp.ProductCategoryEN
)

SELECT
    vc.ProductCategoryEN,
    vc.Ventas,
    vc.CalificacionPromedio,
    ISNULL(d.TotalDevoluciones,0) AS TotalDevoluciones
FROM VentasCategoria vc
LEFT JOIN Devoluciones d
    ON vc.ProductCategoryEN = d.ProductCategoryEN
WHERE vc.Ventas <
(
    SELECT AVG(Ventas)
    FROM VentasCategoria
)
ORDER BY
    TotalDevoluciones DESC,
    Ventas ASC;

-----PREGUNTA 2

WITH VentasProducto AS
(
    SELECT
        dp.ProductID,
        dp.ProductCategoryEN,
        SUM(fs.SalesAmount) AS Ventas,
        SUM(fs.Quantity) AS CantidadVendida,
        AVG(fs.ReviewScore) AS Calificacion
    FROM FactSales fs
    INNER JOIN DimProduct dp
        ON fs.ProductKey = dp.ProductKey
    GROUP BY
        dp.ProductID,
        dp.ProductCategoryEN
)

SELECT
    ProductID,
    ProductCategoryEN,
    Ventas,
    CantidadVendida,
    Calificacion
FROM VentasProducto
WHERE Ventas <
(
    SELECT AVG(Ventas)
    FROM VentasProducto
)
AND Calificacion < 3
ORDER BY Ventas;


/* pregunta 2 revisada*/

WITH IndicadoresProducto AS
(
    SELECT
        dp.ProductID,
        dp.ProductCategoryEN,
        SUM(fs.SalesAmount) AS VentasTotales,
        AVG(CAST(fs.ReviewScore AS DECIMAL(10,2)))
            AS CalificacionPromedio,
        SUM(
            CASE
                WHEN dos.OrderStatus = 'canceled'
                THEN 1
                ELSE 0
            END
        ) AS TotalDevoluciones
    FROM FactSales fs
    INNER JOIN DimProduct dp
        ON fs.ProductKey = dp.ProductKey
    INNER JOIN DimOrderStatus dos
        ON fs.OrderStatusKey = dos.OrderStatusKey
    GROUP BY
        dp.ProductID,
        dp.ProductCategoryEN
)

SELECT TOP 20
    ProductID,
    ProductCategoryEN,
    VentasTotales,
    CalificacionPromedio,
    TotalDevoluciones,

    CASE
        WHEN CalificacionPromedio <= 2
             AND TotalDevoluciones >= 3
            THEN 'RETIRAR'

        WHEN CalificacionPromedio <= 3
             AND TotalDevoluciones >= 1
            THEN 'REDISEÑAR'

        ELSE 'REVISAR'
    END AS AccionSugerida

FROM IndicadoresProducto

WHERE VentasTotales <
(
    SELECT AVG(VentasTotales)
    FROM IndicadoresProducto
)

ORDER BY
    TotalDevoluciones DESC,
    VentasTotales ASC;


-----PREGUNTA 3
WITH HistorialCliente AS
(
    SELECT
        dc.CustomerUniqueID,
        COUNT(DISTINCT fs.OrderID) AS TotalCompras,
        SUM(fs.SalesAmount) AS TotalGastado,
        MAX(dd.FullDate) AS UltimaCompra
    FROM FactSales fs
    INNER JOIN DimCustomer dc
        ON fs.CustomerKey = dc.CustomerKey
    INNER JOIN DimDate dd
        ON fs.DateKey = dd.DateKey
    GROUP BY dc.CustomerUniqueID
)

SELECT
    CustomerUniqueID,
    TotalCompras,
    TotalGastado,
    UltimaCompra,
    DATEDIFF
    (
        DAY,
        UltimaCompra,
        (SELECT MAX(FullDate) FROM DimDate)
    ) AS DiasSinComprar
FROM HistorialCliente
WHERE DATEDIFF
(
    DAY,
    UltimaCompra,
    (SELECT MAX(FullDate) FROM DimDate)
) > 90
ORDER BY DiasSinComprar DESC;

---------------------------
WITH IndicadoresCliente AS
(
    SELECT
        dc.CustomerUniqueID,
        dg.City,

        COUNT(DISTINCT fs.OrderID) AS TotalCompras,

        SUM(fs.SalesAmount) AS TotalGastado,

        DATEDIFF
        (
            DAY,
            MAX(dd.FullDate),
            (SELECT MAX(FullDate)
             FROM DimDate)
        ) AS DiasSinComprar

    FROM FactSales fs

    INNER JOIN DimCustomer dc
        ON fs.CustomerKey = dc.CustomerKey

    INNER JOIN DimGeography dg
        ON dc.GeographyKey = dg.GeographyKey

    INNER JOIN DimDate dd
        ON fs.DateKey = dd.DateKey

    GROUP BY
        dc.CustomerUniqueID,
        dg.City
)

SELECT
    City,

    COUNT(*) AS CantidadClientes,

    ROUND(
        AVG(CAST(TotalGastado AS DECIMAL(18,2))),
        2
    ) AS PromedioGastado,

    ROUND(
        AVG(CAST(TotalCompras AS DECIMAL(18,2))),
        2
    ) AS PromedioCompras,

    ROUND(
        AVG(CAST(DiasSinComprar AS DECIMAL(18,2))),
        2
    ) AS PromedioDiasSinComprar

FROM IndicadoresCliente

GROUP BY
    City

ORDER BY
    PromedioDiasSinComprar DESC,
    PromedioGastado ASC;


--------------pregunta 4 ------------------

WITH ClientesValor AS
(
    SELECT
        dc.CustomerUniqueID,
        SUM(fs.SalesAmount) AS TotalGastado,
        MAX(dd.FullDate) AS UltimaCompra
    FROM FactSales fs
    INNER JOIN DimCustomer dc
        ON fs.CustomerKey = dc.CustomerKey
    INNER JOIN DimDate dd
        ON fs.DateKey = dd.DateKey
    GROUP BY dc.CustomerUniqueID
)

SELECT
    CustomerUniqueID,
    TotalGastado,
    UltimaCompra
FROM ClientesValor
WHERE TotalGastado >
(
    SELECT AVG(TotalGastado)
    FROM ClientesValor
)
AND DATEDIFF
(
    DAY,
    UltimaCompra,
    (SELECT MAX(FullDate) FROM DimDate)
) > 90
ORDER BY TotalGastado DESC;