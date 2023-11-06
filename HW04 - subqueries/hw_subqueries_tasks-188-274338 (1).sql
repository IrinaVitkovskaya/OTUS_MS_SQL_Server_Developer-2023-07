/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (из в таблицы Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/
--Справочно:
SELECT *
FROM Application.People

SELECT *
FROM Sales.Invoices

-- Через вложенный запрос:
SELECT 
    p.PersonID AS ИД_сотрудника,
    p.FullName AS Полное_имя
FROM 
    Application.People p
WHERE 
    p.IsSalesPerson = 1
    AND p.PersonID NOT IN (
        SELECT DISTINCT i.SalespersonPersonID
        FROM Sales.Invoices i
        WHERE 
            i.InvoiceDate >= '2015-07-04' 
            AND i.InvoiceDate < '2015-07-05'
    );

-- Через WITH (для производных таблиц):
WITH SalesPeople AS (
    SELECT 
        PersonID
    FROM 
        Application.People
    WHERE 
        IsSalesPerson = 1
)
SELECT 
    p.PersonID AS ИД_сотрудника,
    p.FullName AS Полное_имя
FROM 
    SalesPeople sp
JOIN 
    Application.People p ON sp.PersonID = p.PersonID
WHERE 
    p.PersonID NOT IN (
        SELECT DISTINCT i.SalespersonPersonID
        FROM Sales.Invoices i
        WHERE 
            i.InvoiceDate >= '2015-07-04' 
            AND i.InvoiceDate < '2015-07-05'
    );

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/
--Справочно:
SELECT *
FROM Warehouse.StockItems

-- Подзапрос с использованием оператора IN:
SELECT StockItemID, StockItemName, UnitPrice
FROM Warehouse.StockItems
WHERE UnitPrice IN (
    SELECT MIN(UnitPrice)
    FROM Warehouse.StockItems
)

-- Подзапрос с использованием оператора EXISTS:
SELECT StockItemID, StockItemName, UnitPrice
FROM Warehouse.StockItems AS s1
WHERE EXISTS (
    SELECT 1
    FROM Warehouse.StockItems AS s2
    WHERE UnitPrice = (
        SELECT MIN(UnitPrice)
        FROM Warehouse.StockItems
    ) AND s2.StockItemID = s1.StockItemID
)

-- Через вложенный запрос:
SELECT
    p.StockItemID AS ИД_товара,
    p.StockItemName AS Наименование_товара,
    p.UnitPrice AS Цена
FROM
    Warehouse.StockItems p
WHERE
    p.UnitPrice = (
        SELECT
            MIN(UnitPrice)
        FROM
            Warehouse.StockItems
    );

-- Через WITH (для производных таблиц):
WITH MinPrice AS (
    SELECT
        MIN(UnitPrice) AS MinUnitPrice
    FROM
        Warehouse.StockItems
)
SELECT
    p.StockItemID AS ИД_товара,
    p.StockItemName AS Наименование_товара,
    p.UnitPrice AS Цена
FROM
    Warehouse.StockItems p
JOIN
    MinPrice mp ON p.UnitPrice = mp.MinUnitPrice;


/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

--Используя подзапрос:
SELECT c.CustomerID, c.CustomerName, t.TransactionAmount
FROM Sales.CustomerTransactions t
INNER JOIN Sales.Customers c ON t.CustomerID = c.CustomerID
WHERE t.TransactionAmount IN (
    SELECT DISTINCT TOP 5 TransactionAmount
    FROM Sales.CustomerTransactions
    ORDER BY TransactionAmount DESC
)
--Используя общую таблицу выражений (CTE):
WITH RankedTransactions AS (
    SELECT CustomerID, TransactionAmount,
        ROW_NUMBER() OVER (ORDER BY TransactionAmount DESC) AS Rank
    FROM Sales.CustomerTransactions
)
SELECT c.CustomerID, c.CustomerName, r.TransactionAmount
FROM RankedTransactions r
INNER JOIN Sales.Customers c ON c.CustomerID = r.CustomerID
WHERE r.Rank <= 5

/*
4. Выберите города (CityID и CityName), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника (FullName), 
который осуществлял упаковку заказов (PackedByPersonID).

--Справочно в задаче используются столбцы из таблиц:
CityID, CityName в таблице Application.Cities
FullName в таблице Application.People
PackedByPersonID в таблице Sales.Invoices
StockItemID в таблице Warehouse.StockItems

*/
SELECT table_name 
FROM information_schema.columns
WHERE column_name = 'PackedByPersonID';

SELECT table_schema, table_name 
FROM information_schema.columns
WHERE column_name = 'FullName';
/*

--Используя подзапрос:
SELECT DISTINCT
	 cts.CityID, cts.CityName, p.FullName
FROM
	(
		SELECT TOP 3 StockItemID
		FROM Warehouse.StockItems
		ORDER BY UnitPrice DESC
	) si
	INNER JOIN Sales.OrderLines ol ON si.StockItemID = ol.StockItemID
	INNER JOIN Sales.Orders o ON ol.OrderID = o.OrderID
	INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
	INNER JOIN Application.People p ON o.PickedByPersonID = p.PersonID
	INNER JOIN Application.Cities cts ON c.DeliveryCityID = cts.CityID

--Используя общую таблицу выражений (CTE):
WITH Top3StockItems AS (
    SELECT TOP 3 StockItemID
    FROM Warehouse.StockItems
    ORDER BY UnitPrice DESC
)
SELECT DISTINCT cts.CityID, cts.CityName, p.FullName
FROM Top3StockItems si
INNER JOIN Sales.OrderLines ol ON si.StockItemID = ol.StockItemID
INNER JOIN Sales.Orders o ON ol.OrderID = o.OrderID
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
INNER JOIN Application.People p ON o.PickedByPersonID = p.PersonID
INNER JOIN Application.Cities cts ON c.DeliveryCityID = cts.CityID

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --
--Данный запрос выполняет выборку информации о счетах-фактурах из таблицы Sales.Invoices. 
--Запрос включает вычисляемые столбцы SalesPersonName и TotalSummForPickedItems.
--1) Выбирает идентификатор счета-фактуры (InvoiceID) и дату счета-фактуры (InvoiceDate) из таблицы Sales.Invoices.
--2) Вычисляет имя продавца (SalesPersonName) путем объединения таблицы Application.People по идентификатору продавца (SalespersonPersonID) из таблицы Sales.Invoices.
--3) Вычисляет общую сумму счетов-фактур (TotalSummByInvoice) из таблицы Sales.InvoiceLines путем группировки по идентификатору счета-фактуры (InvoiceId). Выбираются только счета-фактуры, общая сумма которых превышает 27000.
--4) Вычисляет общую сумму для товаров, которые были отобраны (TotalSummForPickedItems). 
--Во внутреннем подзапросе выбирается идентификатор заказа (OrderId), для которых была завершена укомплектовка (PickingCompletedWhen не является NULL). Затем, внутренний подзапрос вычисляет сумму выбранных товаров (PickedQuantity * UnitPrice) для выбранного заказа.
--5) Объединяет результаты запросов с разделенными условиями по идентификатору счета-фактуры (InvoiceID).
--6) Упорядочивает результаты по общей сумме (TotalSumm) в порядке убывания.
-- Оптимизация запроса:
--Использование подзапросов и оператора ORDER BY может влиять на производительность. Рекомендуется использовать JOINs вместо подзапросов, где это возможно.
--Можно использовать индексы на соответствующих столбцах для оптимизации выполнения запроса.
--Если возможно, следует избегать вычислений в подзапросах и перенести их в основной запрос с использованием соединений и агрегатных функций.

--Приведенный код запроса можно оптимизировать следующим образом:
--сумма выбранных товаров для каждого счета-фактуры вычисляется из таблицы Sales.OrderLines, связанных с таблицами Sales.Orders, и фильтруется только выбранные товары (которые имеют дату завершения укомплектовки отличную от NULL).
--1 вариант:
SELECT 
  i.InvoiceID, 
  i.InvoiceDate,
  p.FullName AS SalesPersonName,
  st.TotalSumm AS TotalSummByInvoice, 
  SUM(ol.PickedQuantity * ol.UnitPrice) AS TotalSummForPickedItems
FROM Sales.Invoices i 
JOIN Application.People p ON p.PersonID = i.SalespersonPersonID
JOIN (
  SELECT InvoiceId, SUM(Quantity * UnitPrice) AS TotalSumm
  FROM Sales.InvoiceLines
  GROUP BY InvoiceId
  HAVING SUM(Quantity * UnitPrice) > 27000
) AS st ON i.InvoiceID = st.InvoiceID
JOIN Sales.Orders o ON o.OrderId = i.OrderId
JOIN Sales.OrderLines ol ON ol.OrderId = o.OrderId
WHERE o.PickingCompletedWhen IS NOT NULL
GROUP BY i.InvoiceID, i.InvoiceDate, p.FullName, st.TotalSumm
ORDER BY st.TotalSumm DESC

SELECT 
  Invoices.InvoiceID, 
  Invoices.InvoiceDate,
  People.FullName AS SalesPersonName,
  SalesTotals.TotalSumm AS TotalSummByInvoice, 
  Orders.OrderTotalSumm AS TotalSummForPickedItems
FROM Sales.Invoices 
JOIN Application.People AS People ON Invoices.SalespersonPersonID = People.PersonID
JOIN (
  SELECT 
    InvoiceId, 
    SUM(Quantity * UnitPrice) AS TotalSumm
  FROM Sales.InvoiceLines
  GROUP BY InvoiceId
  ) AS SalesTotals ON Invoices.InvoiceID = SalesTotals.InvoiceID
JOIN (
  SELECT 
    Invoices.OrderId,
    SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice) AS OrderTotalSumm
  FROM Sales.Invoices AS Invoices
  JOIN Sales.Orders AS Orders ON Orders.OrderId = Invoices.OrderId
  JOIN Sales.OrderLines AS OrderLines ON OrderLines.OrderId = Invoices.OrderId
  WHERE Orders.PickingCompletedWhen IS NOT NULL
  GROUP BY Invoices.OrderId
) AS Orders ON Orders.OrderId = Invoices.OrderId
WHERE SalesTotals.TotalSumm > 27000
ORDER BY TotalSummByInvoice DESC;
