-- В данном скрипте SQL происходит настройка системы обмена сообщениями в базе данных "WideWorldImporters". 
-- Скрипт включает брокера сообщений, создает типы сообщений и контракт, а также создает очереди и сервисы для обмена сообщениями. 
-- Скрипт создает таблицу для хранения отчетов и две хранимые процедуры для формирования запросов и создания отчетов на основе полученных данных.

-- 1. Включение брокера сообщений для базы данных "WideWorldImporters". 
-- Сначала устанавливается односеансный режим подключения к базе данных и отменяются все активные транзакции. 
-- Затем включается брокер сообщений, и в конце устанавливается многопользовательский режим подключения.
ALTER DATABASE [WideWorldImporters] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
ALTER DATABASE [WideWorldImporters] SET ENABLE_BROKER
ALTER DATABASE [WideWorldImporters] SET MULTI_USER

-- 2. Создание типов сообщений
-- В этой части кода создаются два типа сообщений: "//WWI/Report/RequestMessage" и "//WWI/Report/ReplyMessage". 
-- Каждый тип сообщения имеет валидацию в формате WELL_FORMED_XML.
USE WideWorldImporters
-- Для запроса
CREATE MESSAGE TYPE
[//WWI/Report/RequestMessage]
VALIDATION=WELL_FORMED_XML;
-- Для ответа
CREATE MESSAGE TYPE
[//WWI/Report/ReplyMessage]
VALIDATION=WELL_FORMED_XML; 

GO

-- 3. Создание контракта
-- В этой части кода создается контракт "//WWI/Report/Contract", который определяет типы сообщений, отправляемые и принимаемые в рамках контракта. 
-- Контракт указывает, что тип сообщения "//WWI/Report/RequestMessage" отправляется инициатором, а тип сообщения "//WWI/Report/ReplyMessage" отправляется целью.
CREATE CONTRACT [//WWI/Report/Contract]
      ([//WWI/Report/RequestMessage] SENT BY INITIATOR,
       [//WWI/Report/ReplyMessage] SENT BY TARGET
      );
GO


-- 4. Создание очередей и сервисов
-- В этой части кода создаются две очереди: "TargetReportQueueWWI" и "InitiatorReportQueueWWI". 
-- Каждая очередь связывается с соответствующим сервисом, который использует созданный контракт "//WWI/Report/Contract".

-- Первая очередь:
CREATE QUEUE TargetReportQueueWWI;

CREATE SERVICE [//WWI/Report/TargetService]
       ON QUEUE TargetReportQueueWWI
       ([//WWI/Report/Contract]);
GO

-- Вторая очередь:
CREATE QUEUE InitiatorReportQueueWWI;

CREATE SERVICE [//WWI/Report/InitiatorService]
       ON QUEUE InitiatorReportQueueWWI
       ([//WWI/Report/Contract]);
GO


-- 5. Создание таблицы для хранения отчетов
-- В этой части кода создается таблица "Reports" с двумя столбцами: "id" (первичный ключ) и "xml_data" (XML-данные отчета). 
-- Эта таблица будет использоваться для хранения сформированных отчетов.
CREATE TABLE Reports
(
  id INT PRIMARY KEY IDENTITY(1,1),
  xml_data XML NOT NULL,
);


-- 6. Создание хранимой процедуры формирования заявки для создания нового отчета
-- В этой части кода создается хранимая процедура "GetReport", которая принимает три параметра: "CustomerID", "BeginDate" и "EndDate". 
-- Внутри процедуры формируется XML-запрос на основе переданных параметров, инициируется диалог между инициатором ("InitiatorService") и целью ("TargetService") с помощью контракта "//WWI/Report/Contract", и запрос отправляется в очередь для создания отчета.
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetReport
  @CustomerID INT,
  @BeginDate date,
  @EndDate date
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
  DECLARE @RequestMessage NVARCHAR(4000);

  BEGIN TRAN

  SELECT @RequestMessage = (SELECT  @CustomerID as CustomerID, @BeginDate  as BeginDate, @EndDate as EndDate from [Sales].[Customers] Where CustomerID= @CustomerID 
    FOR XML AUTO, root('RequestMessage'));

  BEGIN DIALOG @InitDlgHandle
  FROM SERVICE
  [//WWI/Report/InitiatorService]
  TO SERVICE
  '//WWI/Report/TargetService'
  ON CONTRACT
  [//WWI/Report/Contract]
  WITH ENCRYPTION=OFF;

  SEND ON CONVERSATION @InitDlgHandle 
  MESSAGE TYPE
  [//WWI/Report/RequestMessage]
  (@RequestMessage);

  SELECT @RequestMessage AS SentRequestMessage;

  COMMIT TRAN
END
GO


-- 7. Создание хранимой процедуры обработки очереди TargetReportQueueWWI (создания отчетов)
-- В этой части кода создается хранимая процедура "CreateReport", которая обрабатывает очередь "TargetReportQueueWWI" и создает отчеты на основе полученных данных из запроса. 
-- Процедура извлекает сообщение из очереди, извлекает данные о клиенте, начальной и конечной дате из XML-сообщения, создает отчет на основе этих данных и отправляет ответное сообщение в очередь.
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateReport]
AS
BEGIN

  DECLARE @TargetDlgHandle UNIQUEIDENTIFIER,
      @Message NVARCHAR(4000),
      @MessageType Sysname,
      @ReplyMessage NVARCHAR(4000),
      @CustomerID INT,
      @BeginDate date,
      @EndDate date,
      @xml XML;

  BEGIN TRAN;

  RECEIVE TOP(1)
    @TargetDlgHandle = Conversation_Handle,
    @Message = Message_Body,
    @MessageType = Message_Type_Name
  FROM dbo.TargetReportQueueWWI;

  SELECT @Message;

  SET @xml = CAST(@Message AS XML);

  SELECT
    @CustomerID = R.Iv.value('@CustomerID','INT'),
    @BeginDate = R.Iv.value('@BeginDate','DATE'),
    @EndDate = R.Iv.value('@EndDate','DATE')
  FROM @xml.nodes('/RequestMessage/Sales.Customers') as R(Iv);

  Select 
   @CustomerID as CustomerID,
    @BeginDate  as CustomerID,
   @EndDate  as EndDate 


  IF @MessageType=N'//WWI/Report/RequestMessage'
  BEGIN


    SELECT @ReplyMessage = (SELECT
        CustomerID as CustomerID,
        count(*) as Count
      FROM [WideWorldImporters].[Sales].[Orders]
      Where
        CustomerID = @CustomerID
        AND OrderDate between @BeginDate AND @EndDate
      Group By
        CustomerID
      FOR XML AUTO, root('Report'));


    SEND ON CONVERSATION @TargetDlgHandle
    MESSAGE TYPE
    [//WWI/Report/ReplyMessage]
    (@ReplyMessage);
    END CONVERSATION @TargetDlgHandle;
  END

  SELECT @ReplyMessage AS SentReplyMessage;


 COMMIT TRAN;

END
