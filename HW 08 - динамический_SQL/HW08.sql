/*Более подробно задание описано в материалах в личном кабинете.
Пишем динамический PIVOT.
По заданию из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT".
Требуется написать запрос, который в результате своего выполнения
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.
Нужно написать запрос, который будет генерировать результаты для всех клиентов.
Имя клиента указывать полностью из поля CustomerName.
*/

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
