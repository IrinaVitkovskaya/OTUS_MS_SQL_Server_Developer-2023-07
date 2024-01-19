
--������� ��������� ������� ������ ��������� ����������� � ���������� �������. 
--��������� ����� ������� ����� ������, ��������, ��� �������� ���������� ��������� 
--������� ��������.
CREATE FUNCTION SplitString (@text NVARCHAR(max), @delimiter nchar(1))
RETURNS @Tbl TABLE (part nvarchar(max), ID_ORDER integer) AS
BEGIN
  declare @index integer
  declare @part  nvarchar(max)
  declare @i   integer
  set @index = -1
  set @i=1
  while (LEN(@text) > 0) begin
    set @index = CHARINDEX(@delimiter, @text)
    if (@index = 0) AND (LEN(@text) > 0) BEGIN
      set @part = @text
      set @text = ''
    end else if (@index > 1) begin
      set @part = LEFT(@text, @index - 1)
      set @text = RIGHT(@text, (LEN(@text) - @index))
    end else begin
      set @text = RIGHT(@text, (LEN(@text) - @index))
    end
    insert into @Tbl(part, ID_ORDER) values(@part, @i)
    set @i=@i+1
  end
  RETURN
END
go


select part into #tmpIDs1 from SplitString('11,22,33,44', ',')


Select * from #tmpIDs1

--������ ����� ����������� ������
--����� �������� � VS ��������������� ���������� DemoSQL_CLR.dll �� �#
--��������� ������������� CLR � SQL Server.
EXEC sp_configure 'clr enabled', 1
go
reconfigure
go

EXEC sp_configure 'clr strict security',0;
go
reconfigure
go
--���������� ������

DROP ASSEMBLY IF EXISTS CLRFunctions
go
CREATE ASSEMBLY CLRFunctions FROM 'C:\SplitString.dll'
go
--
--� ��������� ���������������� �������.
CREATE FUNCTION [dbo].SplitStringCLR(@text [nvarchar](max), @delimiter [nchar](1))
RETURNS TABLE (
part nvarchar(max),
ID_ODER int
) WITH EXECUTE AS CALLER
AS
EXTERNAL NAME CLRFunctions.UserDefinedFunctions.SplitString
go