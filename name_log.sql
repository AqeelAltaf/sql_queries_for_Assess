CREATE VIEW dbo.VW_IMIS_Name_Log AS 
(select 
namelog.DATE_TIME as [DATE_TIME],
namelog.LOG_TYPE as [record action],
namelog.USER_ID as [Change_Made_by],
-- search Name_Log.Id in salesforce accounts and then put SF record id of the found account in this column.
acc.ID   as [record_Id],
namelog.LOG_TEXT as [New_Value],
'Account' as [Type]
from IMIS.dbo.Name_Log namelog
LEFT JOIN BOOMI_DEV.dbo.PRODAccounts acc ON namelog.ID = acc.TOURISM_ID__C)