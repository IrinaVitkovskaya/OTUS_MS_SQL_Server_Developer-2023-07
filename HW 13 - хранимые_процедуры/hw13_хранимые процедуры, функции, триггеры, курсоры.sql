/*
Написать функцию возвращающую Клиента с наибольшей суммой покупки.
Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла.
Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему.
*/
--Создание функции, возвращающей клиента с наибольшей суммой покупки:

CREATE FUNCTION GetCustomerWithMaxPurchase()
RETURNS TABLE
AS
RETURN
    SELECT TOP 1
        c.CustomerID,
        c.CustomerName,
        SUM(il.Quantity * il.UnitPrice) AS TotalPurchaseAmount
    FROM
        Sales.Customers c
        INNER JOIN Sales.Invoices i ON c.CustomerID = i.CustomerID
        INNER JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
    GROUP BY
        c.CustomerID,
        c.CustomerName
    ORDER BY
        TotalPurchaseAmount DESC;

--Создание хранимой процедуры, возвращающей сумму покупки по заданному CustomerID:

CREATE PROCEDURE GetPurchaseAmountByCustomer
    @CustomerID INT
AS
BEGIN
    SELECT
        SUM(il.Quantity * il.UnitPrice) AS TotalPurchaseAmount
    FROM
        Sales.Customers c
        INNER JOIN Sales.Invoices i ON c.CustomerID = i.CustomerID
        INNER JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
    WHERE
        c.CustomerID = @CustomerID;
END;

--Создание табличной функции, которая вызывается для каждой строки result set'а без использования цикла:

CREATE FUNCTION CalculatePurchaseAmountForCustomer(@CustomerID INT)
RETURNS @Result TABLE (
    CustomerID INT,
    TotalPurchaseAmount DECIMAL(18, 2)
)
AS
BEGIN
    INSERT INTO @Result (CustomerID, TotalPurchaseAmount)
    SELECT
        @CustomerID,
        SUM(il.Quantity * il.UnitPrice) AS TotalPurchaseAmount
    FROM
        Sales.Invoices i
        INNER JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
    WHERE
        i.CustomerID = @CustomerID
    GROUP BY
        i.CustomerID;

    RETURN;
END;

-- примеры вызова функций и процедуры:

-- Вызов функции GetCustomerWithMaxPurchase
SELECT *
FROM dbo.GetCustomerWithMaxPurchase();

-- Вызов хранимой процедуры GetPurchaseAmountByCustomer с передачей параметра CustomerID
DECLARE @CustomerID INT = 1;
EXEC GetPurchaseAmountByCustomer @CustomerID;

-- Вызов табличной функции CalculatePurchaseAmountForCustomer для каждой строки в result set'е
SELECT
    c.CustomerID,
    f.TotalPurchaseAmount
FROM
    Sales.Customers c
    CROSS APPLY dbo.CalculatePurchaseAmountForCustomer(c.CustomerID) f;