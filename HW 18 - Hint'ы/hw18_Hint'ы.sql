--Оптимизируйте запрос по БД WorldWideImporters.
Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det
ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv
ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans
ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans
ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND (Select SupplierId
FROM Warehouse.StockItems AS It
Where It.StockItemID = det.StockItemID) = 12
AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
FROM Sales.OrderLines AS Total
Join Sales.Orders AS ordTotal
On ordTotal.OrderID = Total.OrderID
WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

--Оптимизированный код запроса:
--Условие WHERE для проверки столбца SupplierId было заменено на соединение с таблицей Warehouse.StockItems.
--Условие для сравнения суммы было заменено на оператор EXISTS с подзапросом, который группирует и проверяет сумму.
--Вместо использования функции DATEDIFF сокращенный алиас DAY был использован для читаемости кода.
SELECT ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
JOIN Warehouse.StockItems AS It ON It.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND It.SupplierId = 12
AND EXISTS (SELECT 1
            FROM Sales.OrderLines AS Total
            JOIN Sales.Orders AS ordTotal ON ordTotal.OrderID = Total.OrderID
            WHERE ordTotal.CustomerID = Inv.CustomerID
            GROUP BY ordTotal.CustomerID
            HAVING SUM(Total.UnitPrice*Total.Quantity) > 250000)
AND DATEDIFF(DAY, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID
