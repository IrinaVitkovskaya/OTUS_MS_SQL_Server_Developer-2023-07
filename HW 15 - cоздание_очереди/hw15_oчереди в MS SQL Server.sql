-- � ������ ������� SQL ���������� ��������� ������� ������ ����������� � ���� ������ "WideWorldImporters". 
-- ������ �������� ������� ���������, ������� ���� ��������� � ��������, � ����� ������� ������� � ������� ��� ������ �����������. 
-- ������ ������� ������� ��� �������� ������� � ��� �������� ��������� ��� ������������ �������� � �������� ������� �� ������ ���������� ������.

-- 1. ��������� ������� ��������� ��� ���� ������ "WideWorldImporters". 
-- ������� ��������������� ������������ ����� ����������� � ���� ������ � ���������� ��� �������� ����������. 
-- ����� ���������� ������ ���������, � � ����� ��������������� ��������������������� ����� �����������.
ALTER DATABASE [WideWorldImporters] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
ALTER DATABASE [WideWorldImporters] SET ENABLE_BROKER
ALTER DATABASE [WideWorldImporters] SET MULTI_USER

-- 2. �������� ����� ���������
-- � ���� ����� ���� ��������� ��� ���� ���������: "//WWI/Report/RequestMessage" � "//WWI/Report/ReplyMessage". 
-- ������ ��� ��������� ����� ��������� � ������� WELL_FORMED_XML.
USE WideWorldImporters
-- ��� �������
CREATE MESSAGE TYPE
[//WWI/Report/RequestMessage]
VALIDATION=WELL_FORMED_XML;
-- ��� ������
CREATE MESSAGE TYPE
[//WWI/Report/ReplyMessage]
VALIDATION=WELL_FORMED_XML; 

GO

-- 3. �������� ���������
-- � ���� ����� ���� ��������� �������� "//WWI/Report/Contract", ������� ���������� ���� ���������, ������������ � ����������� � ������ ���������. 
-- �������� ���������, ��� ��� ��������� "//WWI/Report/RequestMessage" ������������ �����������, � ��� ��������� "//WWI/Report/ReplyMessage" ������������ �����.
CREATE CONTRACT [//WWI/Report/Contract]
      ([//WWI/Report/RequestMessage] SENT BY INITIATOR,
       [//WWI/Report/ReplyMessage] SENT BY TARGET
      );
GO


-- 4. �������� �������� � ��������
-- � ���� ����� ���� ��������� ��� �������: "TargetReportQueueWWI" � "InitiatorReportQueueWWI". 
-- ������ ������� ����������� � ��������������� ��������, ������� ���������� ��������� �������� "//WWI/Report/Contract".

-- ������ �������:
CREATE QUEUE TargetReportQueueWWI;

CREATE SERVICE [//WWI/Report/TargetService]
       ON QUEUE TargetReportQueueWWI
       ([//WWI/Report/Contract]);
GO

-- ������ �������:
CREATE QUEUE InitiatorReportQueueWWI;

CREATE SERVICE [//WWI/Report/InitiatorService]
       ON QUEUE InitiatorReportQueueWWI
       ([//WWI/Report/Contract]);
GO


-- 5. �������� ������� ��� �������� �������
-- � ���� ����� ���� ��������� ������� "Reports" � ����� ���������: "id" (��������� ����) � "xml_data" (XML-������ ������). 
-- ��� ������� ����� �������������� ��� �������� �������������� �������.
CREATE TABLE Reports
(
  id INT PRIMARY KEY IDENTITY(1,1),
  xml_data XML NOT NULL,
);


-- 6. �������� �������� ��������� ������������ ������ ��� �������� ������ ������
-- � ���� ����� ���� ��������� �������� ��������� "GetReport", ������� ��������� ��� ���������: "CustomerID", "BeginDate" � "EndDate". 
-- ������ ��������� ����������� XML-������ �� ������ ���������� ����������, ������������ ������ ����� ����������� ("InitiatorService") � ����� ("TargetService") � ������� ��������� "//WWI/Report/Contract", � ������ ������������ � ������� ��� �������� ������.
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


-- 7. �������� �������� ��������� ��������� ������� TargetReportQueueWWI (�������� �������)
-- � ���� ����� ���� ��������� �������� ��������� "CreateReport", ������� ������������ ������� "TargetReportQueueWWI" � ������� ������ �� ������ ���������� ������ �� �������. 
-- ��������� ��������� ��������� �� �������, ��������� ������ � �������, ��������� � �������� ���� �� XML-���������, ������� ����� �� ������ ���� ������ � ���������� �������� ��������� � �������.
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
