/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/
--проверяем, что есть в таблице:
Select TOP 5 *
FROM [Sales].[Customers]
Order by CustomerID

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Customers' AND TABLE_SCHEMA = 'Sales'
ORDER BY ORDINAL_POSITION;

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Customers' AND TABLE_SCHEMA = 'Sales' AND IS_NULLABLE = 'NO';

SELECT COLUMN_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Customers' 
AND TABLE_SCHEMA = 'Sales' 
AND COLUMNPROPERTY(object_id(TABLE_SCHEMA + '.' + TABLE_NAME), COLUMN_NAME, 'IsIdentity') = 1;

SELECT COLUMN_NAME, DATA_TYPE, COLUMN_DEFAULT, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Customers' AND TABLE_SCHEMA = 'Sales';



-- Пример добавления записей в таблицу Sales.Customers
-- образец вставляет новую запись, которая является копией существующей записи с CustomerID = 3, за исключением некоторых изменений в столбцах CustomerID и CustomerName.
insert Sales.Customers(CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy)
SELECT NEXT VALUE FOR Sequences.CustomerID AS newCustomerID, CustomerName + '_1', BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy
FROM Sales.Customers
where CustomerID = 3

insert Sales.Customers(CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy)
SELECT NEXT VALUE FOR Sequences.CustomerID AS newCustomerID, CustomerName + '_2', BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy
FROM Sales.Customers
where CustomerID = 3

insert Sales.Customers(CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy)
SELECT NEXT VALUE FOR Sequences.CustomerID AS newCustomerID, CustomerName + '_3', BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy
FROM Sales.Customers
where CustomerID = 3

insert Sales.Customers(CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy)
SELECT NEXT VALUE FOR Sequences.CustomerID AS newCustomerID, CustomerName + '_4', BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy
FROM Sales.Customers
where CustomerID = 3

insert Sales.Customers(CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy)
SELECT NEXT VALUE FOR Sequences.CustomerID AS newCustomerID, CustomerName + '_5', BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy
FROM Sales.Customers
where CustomerID = 3


-- образец вставляет новую запись, которая является копией существующей записи с CustomerID = 3, за исключением некоторых изменений в столбцах CustomerID и CustomerName.
insert Sales.Customers(CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy)
SELECT NEXT VALUE FOR Sequences.CustomerID AS newCustomerID, CustomerName + '_1', BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy
FROM Sales.Customers
where CustomerID = 3

SELECT *
FROM Sales.Customers
Order by CustomerID
/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE FROM Sales.Customers
WHERE CustomerID = (SELECT MAX(CustomerID) FROM Sales.Customers) AND CustomerName LIKE '%_5';

/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE Sales.Customers
SET CustomerName = 'Tailspin Toys (Peeples Valley, AZ)_5'
WHERE CustomerID = (SELECT MAX(CustomerID) FROM Sales.Customers) AND CustomerName LIKE '%_4';

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/
MERGE INTO Sales.Customers AS target
USING (
    SELECT CustomerID, 'Tailspin Toys (Peeples Valley, AZ)_4', BillToCustomerID, CustomerCategoryID, BuyingGroupID,
           PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID,
           PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage,
           IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun,
           RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
           DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy
    FROM Sales.Customers
    WHERE CustomerID = 1080
) AS source (CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID,
             PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID,
             PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage,
             IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun,
             RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
             DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy)
ON (target.CustomerID = source.CustomerID)
WHEN MATCHED THEN
    UPDATE SET 
        target.CustomerName = source.CustomerName,
        target.BillToCustomerID = source.BillToCustomerID,
        target.CustomerCategoryID = source.CustomerCategoryID,
        target.BuyingGroupID = source.BuyingGroupID,
        target.PrimaryContactPersonID = source.PrimaryContactPersonID,
        target.AlternateContactPersonID = source.AlternateContactPersonID,
        target.DeliveryMethodID = source.DeliveryMethodID,
        target.DeliveryCityID = source.DeliveryCityID,
        target.PostalCityID = source.PostalCityID,
        target.CreditLimit = source.CreditLimit,
        target.AccountOpenedDate = source.AccountOpenedDate,
        target.StandardDiscountPercentage = source.StandardDiscountPercentage,
        target.IsStatementSent = source.IsStatementSent,
        target.IsOnCreditHold = source.IsOnCreditHold,
        target.PaymentDays = source.PaymentDays,
        target.PhoneNumber = source.PhoneNumber,
        target.FaxNumber = source.FaxNumber,
        target.DeliveryRun = source.DeliveryRun,
        target.RunPosition = source.RunPosition,
        target.WebsiteURL = source.WebsiteURL,
        target.DeliveryAddressLine1 = source.DeliveryAddressLine1,
        target.DeliveryAddressLine2 = source.DeliveryAddressLine2,
        target.DeliveryPostalCode = source.DeliveryPostalCode,
        target.DeliveryLocation = source.DeliveryLocation,
        target.PostalAddressLine1 = source.PostalAddressLine1,
        target.PostalAddressLine2 = source.PostalAddressLine2,
        target.PostalPostalCode = source.PostalPostalCode,
        target.LastEditedBy = source.LastEditedBy
WHEN NOT MATCHED THEN
    INSERT (CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID,
            PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID,
            PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage,
            IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun,
            RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
			DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy)
    VALUES (source.CustomerID, source.CustomerName, source.BillToCustomerID, source.CustomerCategoryID,
            source.BuyingGroupID, source.PrimaryContactPersonID, source.AlternateContactPersonID,
            source.DeliveryMethodID, source.DeliveryCityID, source.PostalCityID, source.CreditLimit,
            source.AccountOpenedDate, source.StandardDiscountPercentage, source.IsStatementSent,
            source.IsOnCreditHold, source.PaymentDays, source.PhoneNumber, source.FaxNumber,
            source.DeliveryRun, source.RunPosition, source.WebsiteURL, source.DeliveryAddressLine1,
            source.DeliveryAddressLine2, source.DeliveryPostalCode, source.DeliveryLocation,
            source.PostalAddressLine1, source.PostalAddressLine2, source.PostalPostalCode,
            source.LastEditedBy);

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/
-- Узнаем имя сервера
SELECT @@SERVERNAME --DESKTOP-6CMA153\SQLEXPRESS

-- Включаем расширенные опции
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

-- Включаем xp_cmdshell
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;

-- Проверяем, что изменения вступили в силу
RECONFIGURE WITH OVERRIDE;

-- Перезагружаем службу SQL Server для применения изменений

-- Выгрузка данных из таблицы Sales.Customers в файл
exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Orders" out "D:\hw09\HW09.txt" -T -w -t, -S DESKTOP-6CMA153\SQLEXPRESS'  
--T: для указания использования аутентификации Windows для подключения к серверу SQL Server.
--w: для указания использования формата данных Unicode (UTF-16) при выгрузке данных с помощью bcp. 
--t,: указывает разделитель полей в выходном файле (здесь разделитель - запятая).
--S: указывает на имя сервера, к которому нужно подключиться.
	
-- Загрузка данных из файла в таблицу Sales.Customers
	BULK INSERT Sales.Customers
	FROM "D:\hw09\HW09.txt"
	WITH
	(
		BATCHSIZE = 1000,
		DATAFILETYPE = 'widechar',
		FIELDTERMINATOR = ',',
		ROWTERMINATOR = '\n',
		KEEPNULLS,
		TABLOCK
	);
