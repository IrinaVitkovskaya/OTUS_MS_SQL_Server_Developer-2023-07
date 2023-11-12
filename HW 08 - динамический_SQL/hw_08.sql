/*Более подробно задание описано в материалах в личном кабинете.
Пишем динамический PIVOT.
По заданию из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT".
Требуется написать запрос, который в результате своего выполнения
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.
Нужно написать запрос, который будет генерировать результаты для всех клиентов.
Имя клиента указывать полностью из поля CustomerName.
*/

DECLARE @dml AS NVARCHAR(MAX),
        @CustomerName AS NVARCHAR(MAX)

-- Сохраняем все имена клиентов
SELECT @CustomerName = ISNULL(@CustomerName + ',', '') + QUOTENAME(CustomerName) 
FROM (SELECT DISTINCT CustomerName FROM Sales.Customers) AS CustomerName

-- Преобразуем в PIVOT таблицу
SET @dml = N'
SELECT 
    DATE_MONTH,
    ' + @CustomerName + '
FROM
    (SELECT
        ST.CustomerName,
        COUNT(CT.InvoiceID) AS Quantity,
        DATEFROMPARTS(YEAR(CT.InvoiceDate), MONTH(CT.InvoiceDate), 1) AS DATE_MONTH 
    FROM Sales.Customers ST
    JOIN Sales.Invoices CT ON ST.CustomerID = CT.CustomerID
    GROUP BY ST.CustomerName, DATEFROMPARTS(YEAR(CT.InvoiceDate), MONTH(CT.InvoiceDate), 1)) AS Data
PIVOT
    (SUM(Data.Quantity) FOR CustomerName IN (' + @CustomerName + ')) AS pivt
ORDER BY DATE_MONTH'

EXEC sp_executesql @dml

SELECT @dml -- Раскомментируйте, чтобы увидеть сформированный запрос