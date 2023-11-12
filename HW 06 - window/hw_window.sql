/* Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Нарастающий итог должен быть без оконной функции.
*/

SELECT
    YEAR(o.OrderDate) AS SalesYear,
    MONTH(o.OrderDate) AS SalesMonth,
    SUM(ol.Quantity * ol.UnitPrice) AS CumulativeSales
FROM
    Sales.Orders AS o
    INNER JOIN Sales.OrderLines AS ol ON o.OrderID = ol.OrderID
WHERE
    o.OrderDate >= '2015-01-01'
GROUP BY
    YEAR(o.OrderDate),
    MONTH(o.OrderDate)
ORDER BY
    YEAR(o.OrderDate),
    MONTH(o.OrderDate);

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

/* 2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
Сравните производительность запросов 1 и 2 с помощью set statistics time, io on

-- Для выполнения расчета суммы нарастающим итогом с использованием оконной функции необходимо использовать функцию SUM() OVER() вместо использования группировки и агрегатных функций. 
*/
SELECT
    YEAR(o.OrderDate) AS SalesYear,
    MONTH(o.OrderDate) AS SalesMonth,
    SUM(ol.Quantity * ol.UnitPrice) OVER (PARTITION BY YEAR(o.OrderDate), MONTH(o.OrderDate) ORDER BY o.OrderDate) AS CumulativeSales
FROM
    Sales.Orders AS o
    INNER JOIN Sales.OrderLines AS ol ON o.OrderID = ol.OrderID
WHERE
    o.OrderDate >= '2015-01-01'
ORDER BY
    YEAR(o.OrderDate),
    MONTH(o.OrderDate);

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- 

WITH CumulativeSales AS (
    SELECT
        YEAR(o.OrderDate) AS SalesYear,
        MONTH(o.OrderDate) AS SalesMonth,
        SUM(ol.Quantity * ol.UnitPrice) AS CumulativeSales
    FROM
        Sales.Orders AS o
        INNER JOIN Sales.OrderLines AS ol ON o.OrderID = ol.OrderID
    WHERE
        o.OrderDate >= '2015-01-01'
    GROUP BY
        YEAR(o.OrderDate),
        MONTH(o.OrderDate)
)

--ORDER BY в PARTITION BY не решает проблему дублированных значений.
--Вместо использования оконной функции, можно воспользоваться вспомогательной таблицей или подзапросом для расчета суммы нарастающим итогом. 

SELECT
    SalesYear,
    SalesMonth,
    (
        SELECT
            SUM(ol.Quantity * ol.UnitPrice)
        FROM
            Sales.Orders AS o2
            INNER JOIN Sales.OrderLines AS ol ON o2.OrderID = ol.OrderID
        WHERE
            YEAR(o2.OrderDate) = c.SalesYear AND MONTH(o2.OrderDate) = c.SalesMonth
    ) AS CumulativeSales
FROM
    (
        SELECT
            YEAR(o.OrderDate) AS SalesYear,
            MONTH(o.OrderDate) AS SalesMonth
        FROM
            Sales.Orders AS o
        WHERE
            o.OrderDate >= '2015-01-01'
        GROUP BY
            YEAR(o.OrderDate),
            MONTH(o.OrderDate)
    ) AS c
ORDER BY
    SalesYear,
    SalesMonth;
		
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

/* 3. Вывести список 2х самых популярных продуктов (по количеству проданных)
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

	SELECT
    YEAR(o.OrderDate) AS SalesYear,
    MONTH(o.OrderDate) AS SalesMonth,
    p.StockItemName,
    SUM(ol.Quantity) AS TotalQuantity
FROM
    [Sales].[Orders] AS o
    INNER JOIN [Sales].[OrderLines] AS ol ON o.OrderID = ol.OrderID
    INNER JOIN [Warehouse].[StockItems] AS p ON ol.StockItemID = p.StockItemID
GROUP BY
    YEAR(o.OrderDate),
    MONTH(o.OrderDate),
    p.StockItemName
ORDER BY
    SalesYear, SalesMonth, TotalQuantity DESC;
	
	/*Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
посчитайте общее количество товаров и выведете полем в этом же запросе
посчитайте общее количество товаров в зависимости от первой буквы названия товара
отобразите следующий id товара исходя из того, что порядок отображения товаров по имени
предыдущий ид товара с тем же порядком отображения (по имени)
названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
сформируйте 30 групп товаров по полю вес товара на 1 шт
Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/
WITH NumberedProducts AS (
    SELECT
        ROW_NUMBER() OVER(ORDER BY StockItemName) AS RowNumber,
        StockItemID,
        StockItemName,
        Brand,
        RecommendedRetailPrice,
        COUNT(*) OVER() AS TotalProducts,
        COUNT(*) OVER(PARTITION BY LEFT(StockItemName, 1)) AS ProductsPerLetter,
        LEAD(StockItemID) OVER(ORDER BY StockItemName) AS NextProductID,
        LAG(StockItemID) OVER(ORDER BY StockItemName) AS PreviousProductID,
        LAG(StockItemName, 2, 'No items') OVER(ORDER BY StockItemName) AS PreviousProductName,
        TypicalWeightPerUnit / 1.0 AS WeightPerUnit
    FROM
        Warehouse.StockItems
)
SELECT
    RowNumber,
    StockItemID,
    StockItemName,
    Brand,
    RecommendedRetailPrice,
    TotalProducts,
    ProductsPerLetter,
    NextProductID,
    PreviousProductID,
    PreviousProductName,
    NTILE(30) OVER(ORDER BY WeightPerUnit) AS WeightGroup
FROM
    NumberedProducts;

	/* 5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.

Справочно:  ExtendedPrice минус TaxAmount = итого без учета налогов
*/
SELECT *
FROM Sales.InvoiceLines

SELECT table_schema, table_name 
FROM information_schema.columns
WHERE column_name = 'ExtendedPrice';

WITH LastSale AS (
    SELECT
        s.SalespersonPersonID AS EmployeeID,
        p.FullName AS LastName,
        c.CustomerID,
        c.CustomerName,
        s.InvoiceDate,
        il.ExtendedPrice - il.TaxAmount AS TotalAmount,
        ROW_NUMBER() OVER(PARTITION BY s.SalespersonPersonID ORDER BY s.InvoiceDate DESC) AS RowNumber
    FROM
        Sales.Invoices AS s
        JOIN Sales.InvoiceLines AS il ON s.InvoiceID = il.InvoiceID
        JOIN Sales.Customers AS c ON s.CustomerID = c.CustomerID
        JOIN Application.People AS p ON s.SalespersonPersonID = p.PersonID
)
SELECT
    EmployeeID,
    LastName,
    CustomerID,
    CustomerName,
    InvoiceDate,
    TotalAmount
FROM
    LastSale
WHERE
    RowNumber = 1;
	/* 6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность.
*/
SELECT
    i.CustomerID,
    c.CustomerName,
    il.StockItemID,
    il.UnitPrice,
    i.InvoiceDate
FROM
    Sales.Invoices AS i
    JOIN Sales.Customers AS c ON i.CustomerID = c.CustomerID
    JOIN Sales.InvoiceLines AS il ON i.InvoiceID = il.InvoiceID
WHERE
    il.StockItemID IN (
        SELECT TOP 2 StockItemID
        FROM Sales.InvoiceLines
        WHERE InvoiceID IN (
            SELECT InvoiceID
            FROM Sales.Invoices
            WHERE CustomerID = i.CustomerID
        )
        ORDER BY UnitPrice DESC
    )
ORDER BY
    i.CustomerID,
    il.UnitPrice DESC;

	-- Используя оконные функции:
	WITH RankedInvoiceLines AS (
    SELECT
        i.CustomerID,
        c.CustomerName,
        il.StockItemID,
        il.UnitPrice,
        i.InvoiceDate,
        ROW_NUMBER() OVER(PARTITION BY i.CustomerID ORDER BY il.UnitPrice DESC) AS RowNumber
    FROM
        Sales.Invoices AS i
        JOIN Sales.Customers AS c ON i.CustomerID = c.CustomerID
        JOIN Sales.InvoiceLines AS il ON i.InvoiceID = il.InvoiceID
)
SELECT
    CustomerID,
    CustomerName,
    StockItemID,
    UnitPrice,
    InvoiceDate
FROM
    RankedInvoiceLines
WHERE
    RowNumber <= 2
ORDER BY
    CustomerID,
    UnitPrice DESC;
