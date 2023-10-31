/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
Цену за единицу товара (UnitPrace) смотреть в таблице InvoiceLines.
*/
--Справочно:
SELECT *
FROM 
Sales.InvoiceLines

SELECT *
FROM 
Sales.Invoices

SELECT 
    YEAR(i.InvoiceDate) AS Год_продажи,
    MONTH(i.InvoiceDate) AS Месяц_продажи,
    AVG(il.UnitPrice) AS Средняя_цена_за_месяц,
    SUM(il.UnitPrice * il.Quantity) AS Общая_сумма_продажи
FROM 
    Sales.Invoices i
JOIN
    Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
GROUP BY 
    YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)
ORDER BY 
    Год_продажи, Месяц_продажи

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
Цену за единицу товара (UnitPrace) смотреть в таблице InvoiceLines.
*/

SELECT 
    YEAR(InvoiceDate) AS Год_продажи,
    MONTH(InvoiceDate) AS Месяц_продажи,
    AVG(UnitPrice) AS Средняя_цена_за_месяц,
    SUM(Quantity * UnitPrice) AS Общая_сумма_продаж
FROM 
    Sales.InvoiceLines il
JOIN 
    Sales.Invoices i ON il.InvoiceID = i.InvoiceID
GROUP BY 
    YEAR(InvoiceDate), MONTH(InvoiceDate)
HAVING 
    SUM(Quantity * UnitPrice) > 4600000
ORDER BY 
    Год_продажи, Месяц_продажи

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
Цену за единицу товара (UnitPrace) смотреть в таблице InvoiceLines.
*/

SELECT 
    YEAR(i.InvoiceDate) AS Год_продажи,
    MONTH(i.InvoiceDate) AS Месяц_продажи,
    p.StockItemName AS Наименование_товара,
    SUM(il.Quantity * il.UnitPrice) AS Сумма_продаж,
    MIN(i.InvoiceDate) AS Дата_первой_продажи,
    SUM(il.Quantity) AS Количество_проданного
FROM
    Sales.Invoices i
JOIN
    Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
JOIN
    Warehouse.StockItems p ON il.StockItemID = p.StockItemID
GROUP BY
    YEAR(i.InvoiceDate),
    MONTH(i.InvoiceDate),
    p.StockItemName
HAVING
    SUM(il.Quantity) < 50
ORDER BY
    Год_продажи,
    Месяц_продажи,
    Наименование_товара;

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
--2
SELECT 
    y.Год_продажи,
    m.Месяц_продажи,
    p.StockItemName AS Наименование_товара,
    ISNULL(SUM(ISNULL(il.Quantity * il.UnitPrice, 0)), 0) AS Сумма_продаж,
    MIN(i.InvoiceDate) AS Дата_первой_продажи,
    ISNULL(SUM(ISNULL(il.Quantity, 0)), 0) AS Количество_проданного
FROM
    (SELECT DISTINCT YEAR(InvoiceDate) AS Год_продажи FROM Sales.Invoices) AS y
CROSS JOIN
    (SELECT DISTINCT MONTH(InvoiceDate) AS Месяц_продажи FROM Sales.Invoices) AS m
CROSS JOIN
    Warehouse.StockItems p
LEFT JOIN
    Sales.Invoices i ON YEAR(i.InvoiceDate) = y.Год_продажи AND MONTH(i.InvoiceDate) = m.Месяц_продажи
LEFT JOIN
    Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID AND il.StockItemID = p.StockItemID
GROUP BY
    y.Год_продажи,
    m.Месяц_продажи,
    p.StockItemName
ORDER BY
    y.Год_продажи,
    m.Месяц_продажи,
    Наименование_товара;

--3
SELECT
    y.Год_продажи,
    m.Месяц_продажи,
    p.StockItemName AS Наименование_товара,
    SUM(ISNULL(il.Quantity * il.UnitPrice, 0)) AS Сумма_продаж,
    MIN(i.InvoiceDate) AS Дата_первой_продажи,
    SUM(ISNULL(il.Quantity, 0)) AS Количество_проданного
FROM
    (SELECT DISTINCT YEAR(InvoiceDate) AS Год_продажи FROM Sales.Invoices) AS y
CROSS JOIN
    (SELECT DISTINCT MONTH(InvoiceDate) AS Месяц_продажи FROM Sales.Invoices) AS m
CROSS JOIN
    Warehouse.StockItems p
LEFT JOIN
    Sales.Invoices i ON YEAR(i.InvoiceDate) = y.Год_продажи AND MONTH(i.InvoiceDate) = m.Месяц_продажи
LEFT JOIN
    Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID AND il.StockItemID = p.StockItemID
GROUP BY
    y.Год_продажи,
    m.Месяц_продажи,
    p.StockItemName
HAVING
    SUM(ISNULL(il.Quantity, 0)) < 50
ORDER BY
    y.Год_продажи,
    m.Месяц_продажи,
    Наименование_товара;