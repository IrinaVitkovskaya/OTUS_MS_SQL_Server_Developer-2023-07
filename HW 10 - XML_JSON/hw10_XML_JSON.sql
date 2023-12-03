/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice
Загрузить эти данные в таблицу Warehouse.StockItems.
Существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName).
Сделать два варианта: с помощью OPENXML и через XQuery.
*/
--c использованием OPENXML
--Данная часть запроса отвечает за загрузку данных из XML-файла во временную таблицу #StockItem с использованием OPENXML:
--Переменная в которую считаем файл XML
DECLARE @xmlStockItems XML;
--Считываем XML-файл в переменную
SELECT  @xmlStockItems =BulkColumn
FROM OPENROWSET
(BULK 'D:\hw10\StockItems.xml',
SINGLE_CLOB
) As data;

SELECT @xmlStockItems as [@xmlStockItems];

DECLARE @docHandle INT;
EXEC sp_xml_preparedocument @docHandle OUTPUT,@xmlStockItems 

SELECT @docHandle AS docHandle;

SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
--Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 
  [StockItemName] NVARCHAR(100)  '@Name',
  [SupplierID] INT 'SupplierID',
  [UnitPackageID] INT 'Package/UnitPackageID',
  [OuterPackageID] INT 'Package/OuterPackageID',
  [QuantityPerOuter] INT 'Package/QuantityPerOuter',
  [TypicalWeightPerUnit] DECIMAL (18,3) 'Package/TypicalWeightPerUnit',
  [LeadTimeDays] INT 'LeadTimeDays',
  [IsChillerStock] BIT 'IsChillerStock',
  [TaxRate] DECIMAL (18,3) 'TaxRate',
  [UnitPrice] DECIMAL (18,2) 'UnitPrice');

--Затем происходит вставка полученных данных из временной таблицы #StockItem в таблицу Warehouse.StockItems:
-- Вставляем результат в таблицу
DROP TABLE IF EXISTS #StockItem;

CREATE TABLE #StockItem(
  [StockItemName] NVARCHAR(100),
  [SupplierID] INT,
  [UnitPackageID] INT,
  [OuterPackageID] INT,
  [QuantityPerOuter] INT,
  [TypicalWeightPerUnit] DECIMAL (18,3),
  [LeadTimeDays] INT,
  [IsChillerStock] BIT,
  [TaxRate] DECIMAL (18,3),
  [UnitPrice] DECIMAL (18,2));

INSERT INTO #StockItem
SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
  [StockItemName] NVARCHAR(100)  '@Name',
  [SupplierID] INT 'SupplierID',
  [UnitPackageID] INT 'Package/UnitPackageID',
  [OuterPackageID] INT 'Package/OuterPackageID',
  [QuantityPerOuter] INT 'Package/QuantityPerOuter',
  [TypicalWeightPerUnit] DECIMAL (18,3) 'Package/TypicalWeightPerUnit',
  [LeadTimeDays] INT 'LeadTimeDays',
  [IsChillerStock] BIT 'IsChillerStock',
  [TaxRate] DECIMAL (18,3) 'TaxRate',
  [UnitPrice] DECIMAL (18,2) 'UnitPrice');

SELECT * FROM #StockItem;

-- с использованием XQuery
-- Загрузка XML-файла в переменную @x
DECLARE @x XML;
SET @x = ( 
  SELECT * FROM OPENROWSET
  (BULK 'D:\hw10\StockItems.xml', SINGLE_CLOB) AS d
);

-- Получение значений с использованием XQuery
SELECT 
  @x.query('(/StockItems/Item/SupplierID)') AS [SupplierID],
  @x.value('(/StockItems/Item/SupplierID)[1]', 'int') AS [SupplierID],
  @x.value('(/StockItems/Item/Package/UnitPackageID)[1]', 'INT') AS [UnitPackageID],
  @x.value('(/StockItems/Item/Package/OuterPackageID)[1]', 'INT') AS [OuterPackageID],
  @x.value('(/StockItems/Item/Package/QuantityPerOuter)[1]', 'DECIMAL(18, 2)') AS [QuantityPerOuter],
  @x.value('(/StockItems/Item/Package/TypicalWeightPerUnit)[1]', 'DECIMAL(18, 2)') AS [TypicalWeightPerUnit],
  @x.value('(/StockItems/Item/LeadTimeDays)[1]', 'INT') AS [LeadTimeDays],
  @x.value('(/StockItems/Item/IsChillerStock)[1]', 'BIT') AS [IsChillerStock],
  @x.value('(/StockItems/Item/TaxRate)[1]', 'DECIMAL(18, 2)') AS [TaxRate],
  @x.value('(/StockItems/Item/UnitPrice)[1]', 'DECIMAL(18, 2)') AS [UnitPrice];

-- Создание временной таблицы для XML данных
DROP TABLE IF EXISTS #TempStockItems2;
CREATE TABLE #TempStockItems2 (
    StockItemName NVARCHAR(MAX),
    SupplierID INT,
    UnitPackageID INT,
    OuterPackageID INT,
    QuantityPerOuter DECIMAL(18, 2),
    TypicalWeightPerUnit DECIMAL(18, 2),
    LeadTimeDays INT,
    IsChillerStock BIT,
    TaxRate DECIMAL(18, 2),
    UnitPrice DECIMAL(18, 2)
);

-- Импорт данных из XML во временную таблицу
INSERT INTO #TempStockItems2
SELECT
    StockItem2.value('(@Name)[1]', 'NVARCHAR(MAX)'),
    StockItem2.value('(SupplierID)[1]', 'INT'),
    StockItem2.value('(Package/UnitPackageID)[1]', 'INT'),
    StockItem2.value('(Package/OuterPackageID)[1]', 'INT'),
    StockItem2.value('(Package/QuantityPerOuter)[1]', 'DECIMAL(18, 2)'),
    StockItem2.value('(Package/TypicalWeightPerUnit)[1]', 'DECIMAL(18, 2)'),
    StockItem2.value('(LeadTimeDays)[1]', 'INT'),
    StockItem2.value('(IsChillerStock)[1]', 'BIT'),
    StockItem2.value('(TaxRate)[1]', 'DECIMAL(18, 2)'),
    StockItem2.value('(UnitPrice)[1]', 'DECIMAL(18, 2)')
FROM @x.nodes('/StockItems/Item') AS T(StockItem2);

-- Вывод данных из временной таблицы
SELECT * FROM #TempStockItems2;

-- Далее можно использовать данные из временной таблицы для обновления или добавления записей в таблицу Warehouse.StockItems
-- Обновление и добавление аналогично Варианту 1

/*
Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
Примечания к заданиям 1, 2:
Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML.
Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/

--Данный запрос выполняет выгрузку данных из таблицы Warehouse.StockItems в XML-файл StockItemfull.xml с использованием инструмента BCP.

-- Включаем xp_cmdshell
EXEC sp_configure 'show advanced options', 1;
GO

RECONFIGURE;
GO

EXEC sp_configure 'xp_cmdshell', 1;
GO

RECONFIGURE;
GO

-- Выгрузка данных из таблицы в XML-файл с помощью BCP
EXEC master..xp_cmdshell 'bcp "SELECT StockItemName AS ''StockItem/StockItemName'', SupplierID AS ''StockItem/SupplierID'', UnitPackageID AS ''StockItem/UnitPackageID'', OuterPackageID AS ''StockItem/OuterPackageID'', QuantityPerOuter AS ''StockItem/QuantityPerOuter'', TypicalWeightPerUnit AS ''StockItem/TypicalWeightPerUnit'', LeadTimeDays AS ''StockItem/LeadTimeDays'', IsChillerStock AS ''StockItem/IsChillerStock'', TaxRate AS ''StockItem/TaxRate'', UnitPrice AS ''StockItem/UnitPrice'' FROM [WideWorldImporters].[Warehouse].[StockItems] FOR XML PATH(''StockItemsXML''), ROOT(''StockItems'')" queryout D:\hw10\StockItemfull.xml -T -w -t, -S DESKTOP-6CMA153\SQLEXPRESS';

/*
Выполняя этот запрос, данные из таблицы Warehouse.StockItems будут выгружены в XML-файл StockItemfull.xml. Он будет иметь следующую структуру:
<StockItems>
  <StockItemsXML>
    <StockItem>
      <StockItemName>...</StockItemName>
      <SupplierID>...</SupplierID>
      <UnitPackageID>...</UnitPackageID>
      <OuterPackageID>...</OuterPackageID>
      <QuantityPerOuter>...</QuantityPerOuter>
      <TypicalWeightPerUnit>...</TypicalWeightPerUnit>
      <LeadTimeDays>...</LeadTimeDays>
      <IsChillerStock>...</IsChillerStock>
      <TaxRate>...</TaxRate>
      <UnitPrice>...</UnitPrice>
    </StockItem>
    ...
  </StockItemsXML>
</StockItems>
*/

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
StockItemID
StockItemName
CountryOfManufacture (из CustomFields)
FirstTag (из поля CustomFields, первое значение из массива Tags)
*/
SELECT 
    StockItemID,
    StockItemName,
    JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
    JSON_VALUE(CustomFields, '$.Tags[0]') AS FirstTag
FROM Warehouse.StockItems;

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести:
StockItemID
StockItemName
(опционально) все теги (из CustomFields) через запятую в одном поле
Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.
Должно быть в таком виде:
... where ... = 'Vintage'
Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/
SELECT
    StockItemID,
    StockItemName,
    STRING_AGG(Tag.Value, ', ') AS Tags
FROM
    Warehouse.StockItems
CROSS APPLY OPENJSON(CustomFields, '$.Tags') AS Tag
WHERE
    Tag.Value = 'Vintage'
GROUP BY
    StockItemID,
    StockItemName;
