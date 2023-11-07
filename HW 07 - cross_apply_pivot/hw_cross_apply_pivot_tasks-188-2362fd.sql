/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

SELECT 
    FORMAT(DATEADD(month, DATEDIFF(month, 0, so.OrderDate), 0), 'dd.MM.yyyy') AS InvoiceMonth,
    CASE WHEN c.CustomerID = 2 THEN SUBSTRING(c.CustomerName, CHARINDEX('(', c.CustomerName)+1, LEN(c.CustomerName)-CHARINDEX('(', c.CustomerName)-1) END AS [Peeples Valley, AZ],
    CASE WHEN c.CustomerID = 3 THEN SUBSTRING(c.CustomerName, CHARINDEX('(', c.CustomerName)+1, LEN(c.CustomerName)-CHARINDEX('(', c.CustomerName)-1) END AS [Medicine Lodge, KS],
    CASE WHEN c.CustomerID = 4 THEN SUBSTRING(c.CustomerName, CHARINDEX('(', c.CustomerName)+1, LEN(c.CustomerName)-CHARINDEX('(', c.CustomerName)-1) END AS [Gasport, NY],
    CASE WHEN c.CustomerID = 5 THEN SUBSTRING(c.CustomerName, CHARINDEX('(', c.CustomerName)+1, LEN(c.CustomerName)-CHARINDEX('(', c.CustomerName)-1) END AS [Sylvanite, MT],
    CASE WHEN c.CustomerID = 6 THEN SUBSTRING(c.CustomerName, CHARINDEX('(', c.CustomerName)+1, LEN(c.CustomerName)-CHARINDEX('(', c.CustomerName)-1) END AS [Jessie, ND]
FROM 
    Sales.Orders so
    JOIN Sales.Customers c ON c.CustomerID = so.CustomerID
WHERE 
    c.CustomerID BETWEEN 2 AND 6
GROUP BY 
    FORMAT(DATEADD(month, DATEDIFF(month, 0, so.OrderDate), 0), 'dd.MM.yyyy'),
    c.CustomerID,
    c.CustomerName
ORDER BY 
    InvoiceMonth ASC;

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------

*/
SELECT table_schema, table_name 
FROM information_schema.columns
WHERE column_name = 'DeliveryAddressLine1';

SELECT 
    c.CustomerName,
    c.DeliveryAddressLine1 AS Address
FROM 
    Sales.Customers c
WHERE 
    c.CustomerName LIKE '%Tailspin Toys%'
UNION
SELECT 
    c.CustomerName,
    c.PostalAddressLine1 AS Address
FROM 
    Sales.Customers c
WHERE 
    c.CustomerName LIKE '%Tailspin Toys%'
ORDER BY 
    CustomerName;

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT * 
FROM
    Application.Countries
-- символьный код:
SELECT
    c.CountryID,
    c.CountryName,
    CASE
        WHEN ISNUMERIC(c.IsoAlpha3Code) = 1 THEN CAST(c.IsoAlpha3Code AS VARCHAR(10))
        ELSE c.IsoAlpha3Code
    END AS Code
FROM
    Application.Countries c
ORDER BY
    c.CountryID;
-- символьный + числовой код через запятую:
SELECT CountryId, CountryName, 
       Concat(IsoAlpha3Code, ', ', IsoNumericCode) AS Code
FROM Application.Countries
--символьный + числовой код:
SELECT CountryId, CountryName, IsoAlpha3Code AS Code
FROM Application.Countries

UNION

SELECT CountryId, CountryName, CAST(IsoNumericCode AS NVARCHAR(50)) AS Code
FROM Application.Countries
/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
SELECT table_schema, table_name 
FROM information_schema.columns
WHERE column_name = 'CustomerId';

SELECT *
FROM Sales.CustomerTransactions

SELECT c.CustomerId, c.CustomerName, p.CustomerTransactionId, p.TransactionAmount, p.TransactionDate
FROM Sales.Customers c
CROSS APPLY (
    SELECT TOP 2 CustomerTransactionId, TransactionAmount, TransactionDate
    FROM Sales.CustomerTransactions p
    WHERE p.CustomerId = c.CustomerId
    ORDER BY TransactionAmount DESC
) p
ORDER BY c.CustomerId, p.TransactionAmount DESC


