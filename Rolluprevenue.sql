CREATE VIEW dbo.VW_IMIS_Roll_up_Revenue as
select [Tourism ID],
case when [Roll_up_Revenue_Account__c] = [Tourism ID] then '' else  [Roll_up_Revenue_Account__c] end as [Roll_up_Revenue_Account__c]
from 
(
    select ID as  [Tourism ID],
    IMIS.dbo.fn_COID(ID) as [Roll_up_Revenue_Account__c]
 from IMIS.dbo.Loc_Info    
 ) base