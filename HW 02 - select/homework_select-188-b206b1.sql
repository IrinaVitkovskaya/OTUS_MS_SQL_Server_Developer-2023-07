/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockItemID, StockItemName
FROM Warehouse.StockItems 
WHERE StockItemName LIKE '%urgent%' or StockItemName LIKE 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT s.SupplierID, SupplierName
FROM Purchasing.Suppliers as s LEFT JOIN Purchasing.PurchaseOrders as p
		ON s.SupplierID = p.SupplierID 
WHERE p.SupplierID IS NULL

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT o.OrderID, 
       CONVERT(varchar, o.OrderDate, 104) AS OrderDate, 
       DATENAME(month, o.OrderDate) AS MonthName, 
       DATEPART(quarter, o.OrderDate) AS Quarter, 
       CONCAT(YEAR(o.OrderDate), '-', 
       (MONTH(o.OrderDate) - 1) / 4 * 4 + 1, '-', 
       (MONTH(o.OrderDate) - 1) / 4 * 4 + 4) AS ThirdOfYear, 
       c.CustomerName AS Customer
FROM Sales.Orders o
JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
WHERE ol.UnitPrice > 100 OR ol.Quantity > 20
AND o.PickingCompletedWhen IS NOT NULL
ORDER BY Quarter, ThirdOfYear, o.OrderDate
OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPersonID)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT dm.DeliveryMethodName, po.ExpectedDeliveryDate, s.SupplierName, po.ContactPersonID
FROM Purchasing.Suppliers s
INNER JOIN Purchasing.PurchaseOrders po ON s.SupplierID = po.SupplierID
INNER JOIN Application.DeliveryMethods dm ON po.DeliveryMethodID = dm.DeliveryMethodID
INNER JOIN Application.People p ON po.ContactPersonID = p.PersonID
WHERE po.ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-01-31'
AND (dm.DeliveryMethodName = 'Air Freight' OR dm.DeliveryMethodName = 'Refrigerated Air Freight')
AND po.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) (OrderDate дата продажи=дате заказа?) с именем клиента (CustomerName) и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10
    o.OrderDate,
    c.CustomerName,
    p.FullName AS SalespersonName
FROM
    Sales.Orders o
    INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
    INNER JOIN Application.People p ON o.SalespersonPersonID = p.PersonID
ORDER BY
    o.OrderDate DESC;

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT
    c.CustomerID,
    c.CustomerName,
    c.PhoneNumber
FROM
    Sales.Orders o
    INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
    INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
    INNER JOIN Warehouse.StockItems si ON ol.StockItemID = si.StockItemID
WHERE
    si.StockItemName = 'Chocolate frogs 250g';



	--справочно
SELECT *
FROM Sales.Orders
SELECT *
FROM Sales.OrderLines
SELECT *
FROM Sales.Customers