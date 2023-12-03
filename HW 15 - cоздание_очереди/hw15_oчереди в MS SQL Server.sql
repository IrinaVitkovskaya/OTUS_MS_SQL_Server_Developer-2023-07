/*
Создание очереди в БД для фоновой обработки задачи в БД.
Подумайте и реализуйте очередь в рамках своего проекта.
Если в вашем проекте нет задачи, которая подходит под реализацию через очередь, то в качестве ДЗ:
Реализуйте очередь для БД WideWorldImporters:

1.Создайте очередь для формирования отчетов для клиентов по таблице Invoices. При вызове процедуры для создания отчета в очередь должна отправляться заявка.
2.При обработке очереди создавайте отчет по количеству заказов (Orders) по клиенту за заданный период времени и складывайте готовый отчет в новую таблицу.
3.Проверьте, что вы корректно открываете и закрываете диалоги и у нас они не копятся.
*/
-- Удаляем уже существующие хранимые процедуры, если они есть:
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'AddReportToQueue')
    DROP PROCEDURE AddReportToQueue;
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'ProcessReportQueue')
    DROP PROCEDURE ProcessReportQueue;

-- Создаем таблицы QueueReports и ReportResults, если они еще не созданы:
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'QueueReports')
BEGIN
    CREATE TABLE QueueReports (
        ReportID INT IDENTITY(1,1) PRIMARY KEY,
        CustomerID INT,
        StartDate DATE,
        EndDate DATE,
        Status VARCHAR(10) DEFAULT 'Pending'
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ReportResults')
BEGIN
    CREATE TABLE ReportResults (
        ReportID INT,
        CustomerID INT,
        OrdersCount INT,
        ReportDate DATETIME,
        FOREIGN KEY (ReportID) REFERENCES QueueReports(ReportID)
    );
END;

-- Хранимая процедура AddReportToQueue:
CREATE PROCEDURE AddReportToQueue
    @CustomerID INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    INSERT INTO QueueReports (CustomerID, StartDate, EndDate)
    VALUES (@CustomerID, @StartDate, @EndDate);
END;

-- Хранимая процедура ProcessReportQueue:
CREATE PROCEDURE ProcessReportQueue
AS
BEGIN
    DECLARE @ReportID INT, @CustomerID INT, @StartDate DATE, @EndDate DATE;

    -- Извлечение заявок из очереди
    WHILE EXISTS (SELECT 1 FROM QueueReports WHERE Status = 'Pending')
    BEGIN
        -- Получение первой заявки из очереди
        SELECT TOP 1 @ReportID = ReportID, @CustomerID = CustomerID, @StartDate = StartDate, @EndDate = EndDate
        FROM QueueReports
        WHERE Status = 'Pending'
        ORDER BY ReportID;

        -- Создание отчета и сохранение его в новую таблицу
        INSERT INTO ReportResults (ReportID, CustomerID, OrdersCount, ReportDate)
        SELECT @ReportID, @CustomerID, COUNT(*), GETDATE()
        FROM Sales.Orders
        WHERE CustomerID = @CustomerID AND OrderDate BETWEEN @StartDate AND @EndDate
        GROUP BY CustomerID;

        -- Обновление статуса заявки на "Обработана"
        UPDATE QueueReports
        SET Status = 'Processed'
        WHERE ReportID = @ReportID;
    END;
END;