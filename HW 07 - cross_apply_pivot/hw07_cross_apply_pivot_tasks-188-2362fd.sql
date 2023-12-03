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
GO
WITH ClientCTE (CustomerID, CustomerName,Short_name)  
AS
(	
	Select 
	CustomerID, CustomerName, SUBSTRING(CustomerName,LEN(LEFT(CustomerName,CHARINDEX('(', CustomerName)+1)),LEN(CustomerName) - LEN(LEFT(CustomerName,CHARINDEX('(', CustomerName))) - LEN(RIGHT(CustomerName,CHARINDEX(')', (REVERSE(CustomerName)))))) as Short_name 
	From Sales.Customers 
	ORDER BY CustomerID  OFFSET 1 ROWS FETCH NEXT 5 ROWS ONLY
)
SELECT *
FROM(Select
		ClientCTE.Short_name as SN, 
		COUNT(CT.InvoiceID) as  Quantity,
		CONCAT('01.',RIGHT('00' + CAST(DATEPART(month, CT.InvoiceDate) as Varchar (10)), 2),'.',YEAR(CT.InvoiceDate))as InvoiceMonth --дата в формате дд.мм.гггг
	FROM ClientCTE  join Sales.Invoices as CT
	on ClientCTE.CustomerID=CT.CustomerID
	GROUP BY ClientCTE.CustomerID,CT.CustomerID,
		YEAR(CT.InvoiceDate),
		RIGHT('00' + CAST(DATEPART(month, CT.InvoiceDate) as Varchar (10)), 2),
		ClientCTE.Short_name,
		CONCAT('01.',RIGHT('00' + CAST(DATEPART(month, CT.InvoiceDate) as Varchar (10)), 2),'.',YEAR(CT.InvoiceDate))
	) as Data
PIVOT (SUM(Data.Quantity) For Data.SN IN([Peeples Valley, AZ], [Medicine Lodge, KS],[Gasport, NY],[Sylvanite, MT], [Jessie, ND]))as pvt
Order by InvoiceMonth

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

-- с использованием UNPIVOT
SELECT *
	FROM(
		SELECT CustomerID, CustomerName, DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2 
		FROM Sales.Customers
		Where CustomerName Like '%Tailspin Toys%'	
		) AS Customers
	UNPIVOT (AddressLine FOR Name IN (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2)) AS unpt;


/*
--Предыдущие версии решения задачи:
--Найдем названия таблиц и схем в базе данных, где имеется столбец 'DeliveryAddressLine1'.
SELECT table_schema, table_name 
FROM information_schema.columns
WHERE column_name = 'DeliveryAddressLine1';
-- с использованием pivit
	SELECT
    c.CustomerName,
    u.Address
FROM
    Sales.Customers c
CROSS APPLY
    (VALUES (c.DeliveryAddressLine1), (c.PostalAddressLine1)) as u(Address)
WHERE
    c.CustomerName LIKE '%Tailspin Toys%'
ORDER BY
    CustomerName;
-- с использованием оператора UNION
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
*/

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

--с использованием UNPIVOT
SELECT CountryID, CountryName, Code AS Code
FROM (
    SELECT CountryID, CountryName, CAST(IsoAlpha3Code AS NVARCHAR) AS TextAlphaCode, CAST(IsoNumericCode AS NVARCHAR) AS TextNumericCode 
    FROM Application.Countries
) AS Country
UNPIVOT (Code FOR Name IN (TextAlphaCode, TextNumericCode)) AS unpt;

/*
--Предыдущие версии решения задачи:
-- с использованием оператора UNION
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
*/
/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
WITH WindowFilter AS (
    SELECT 
        si.CustomerID, 
        si.InvoiceDate, 
        sil.StockItemID, 
        sil.ExtendedPrice,
        ROW_NUMBER() OVER (PARTITION BY si.CustomerID ORDER BY sil.ExtendedPrice DESC) AS Number
    FROM 
        Sales.Invoices AS si 
    INNER JOIN 
        Sales.InvoiceLines AS sil ON si.InvoiceID = sil.InvoiceID
)
SELECT 
    unpvt.CustomerID, 
    c.CustomerName AS Name_Customer, 
    unpvt.Name, 
    CAST(unpvt.Value AS nvarchar) AS Value
FROM 
    (
    SELECT 
        CustomerID, 
        StockItemID, 
        CAST(StockItemID AS nvarchar) AS StockItemIDValue, 
        InvoiceDate, 
        CAST(InvoiceDate AS nvarchar) AS InvoiceDateValue, 
        ExtendedPrice, 
        CAST(ExtendedPrice AS nvarchar) AS ExtendedPriceValue
    FROM 
        WindowFilter
    WHERE 
        Number IN (1, 2)
    ) AS p
UNPIVOT 
    (Value FOR Name IN (StockItemIDValue, InvoiceDateValue, ExtendedPriceValue)) AS unpvt
JOIN 
    Sales.Customers AS c ON unpvt.CustomerID = c.CustomerID;

/*
--Предыдущие версии решения задачи:
--
SELECT table_schema, table_name 
FROM information_schema.columns
WHERE column_name = 'CustomerId';
--
SELECT *
FROM Sales.CustomerTransactions
--
SELECT c.CustomerId, c.CustomerName, p.CustomerTransactionId, p.TransactionAmount, p.TransactionDate
FROM Sales.Customers c
CROSS APPLY (
    SELECT TOP 2 CustomerTransactionId, TransactionAmount, TransactionDate
    FROM Sales.CustomerTransactions p
    WHERE p.CustomerId = c.CustomerId
    ORDER BY TransactionAmount DESC
) p
ORDER BY p.TransactionAmount DESC