/*
Выбираем в своем проекте таблицу-кандидат для секционирования и добавляем партиционирование.
Если в проекте нет такой таблицы, то делаем анализ базы данных из первого модуля, выбираем таблицу и делаем ее секционирование, с переносом данных по секциям (партициям) - исходя из того, что таблица большая, пишем скрипты миграции в секционированную таблицу
*/
 
-- Создание файловой группы для партиций
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [YearData];
-- Добавление файла в файловую группу
ALTER DATABASE [WideWorldImporters] ADD FILE 
( 
    NAME = N'Years', 
    FILENAME = N'C:\Users\Irina\Desktop\SQL 2023-2024\HW19\Yeardata.ndf', 
    SIZE = 204800KB, 
    FILEGROWTH = 10240KB 
) TO FILEGROUP [YearData];

-- Создание функции партиционирования по годам
CREATE PARTITION FUNCTION [fnYearPartition](DATE) AS RANGE RIGHT FOR VALUES
(
    '20160101',
    '20170101',
    '20180101',
    '20190101',
    '20200101',
    '20210101',
    '20220101',
    '20230101',
    '20240101',
    '20250101'
);

-- Создание схемы партиционирования
CREATE PARTITION SCHEME [schmYearPartition] AS PARTITION [fnYearPartition] 
ALL TO ([YearData]);

-- Подсчет количества записей в таблице Sales.Orders
SELECT COUNT(*) 
FROM Sales.Orders;

-- Создание партиционированной таблицы
SELECT * INTO Sales.OrdersPartitioned
FROM Sales.Orders;

-- Создание кластеризованного индекса на партиционированной таблице
CREATE CLUSTERED INDEX [ClusteredIndex_on_schmYearPartition_1234567890] ON [Sales].[OrdersPartitioned]
(
    [OrderDate]
)
WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [schmYearPartition]([OrderDate]);

-- Удаление созданного индекса
DROP INDEX [ClusteredIndex_on_schmYearPartition_1234567890] ON [Sales].[OrdersPartitioned];

-- Получение списка партиционированных таблиц
SELECT DISTINCT t.name
FROM sys.partitions p
INNER JOIN sys.tables t ON p.object_id = t.object_id
WHERE p.partition_number <> 1;

-- Получение информации о данных в каждой партиции
SELECT  
    $PARTITION.fnYearPartition(OrderDate) AS Partition,
    COUNT(*) AS [COUNT],
    MIN(OrderDate),
    MAX(OrderDate) 
FROM Sales.OrdersPartitioned
GROUP BY $PARTITION.fnYearPartition(OrderDate)
ORDER BY Partition;  

-- Слияние пустых секций
ALTER PARTITION FUNCTION [fnYearPartition] MERGE RANGE ('20170101');
ALTER PARTITION FUNCTION [fnYearPartition] MERGE RANGE ('20180101');
ALTER PARTITION FUNCTION [fnYearPartition] MERGE RANGE ('20190101');
ALTER PARTITION FUNCTION [fnYearPartition] MERGE RANGE ('20200101');
ALTER PARTITION FUNCTION [fnYearPartition] MERGE RANGE ('20210101');
ALTER PARTITION FUNCTION [fnYearPartition] MERGE RANGE ('20220101');
ALTER PARTITION FUNCTION [fnYearPartition] MERGE RANGE ('20230101');
ALTER PARTITION FUNCTION [fnYearPartition] MERGE RANGE ('20240101');

-- Разделение секции на две
ALTER PARTITION FUNCTION [fnYearPartition] SPLIT RANGE ('20140101');

-- Переключение схемы хранения для последующих партиций
ALTER PARTITION SCHEME [schmYearPartition]  
NEXT USED [YearData]; 

-- Повторное разделение секции
ALTER PARTITION FUNCTION [fnYearPartition] SPLIT RANGE ('20150101');

-- Еще одно разделение секций для равномерного распределения
ALTER PARTITION FUNCTION [fnYearPartition] SPLIT RANGE ('20130701');
ALTER PARTITION FUNCTION [fnYearPartition] SPLIT RANGE ('20140701');
ALTER PARTITION FUNCTION [fnYearPartition] SPLIT RANGE ('20150701');

-- Вывод информации о полученных секциях
SELECT  
    $PARTITION.fnYearPartition(OrderDate) AS Partition,
    COUNT(*) AS [COUNT],
    MIN(OrderDate),
    MAX(OrderDate) 
FROM Sales.OrdersPartitioned
GROUP BY $PARTITION.fnYearPartition(OrderDate)
ORDER BY Partition;  
