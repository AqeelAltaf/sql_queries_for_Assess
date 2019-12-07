CREATE VIEW dbo.VW_IMIS_Roll_up_Revenue as
select [Tourism ID],
case when [Roll_up_Revenue_Account__c] = [Tourism ID] then '' else  [Roll_up_Revenue_Account__c] end as [Roll_up_Revenue_Account__c]
from 
(
    select ID as  [Tourism ID],
    IMIS.dbo.fn_COID(ID) as [Roll_up_Revenue_Account__c]
 from IMIS.dbo.Loc_Info    
 ) base


 select  ID, 
 CATEGORY_TYPE__C, 
 BILL_TO_PARENT__C, 
 BILLING_CYCLE__C, 
 IsExempted,
 case
	when IsExempted = 1  and BILLING_CYCLE__C = 'January' then 1 
	when IsExempted = 1  and BILLING_CYCLE__C = 'July' then 7 end as [Fiscal Start Month] ,
 case
	when IsExempted = 1  and BILLING_CYCLE__C = 'January' then 12 
	when IsExempted = 1  and BILLING_CYCLE__C = 'July' then 6 end as [Fiscal End Month] 

 from
 (select 
 ID, 
 CATEGORY_TYPE__C, 
 BILL_TO_PARENT__C, 
 BILLING_CYCLE__C,
case 
	when CATEGORY_TYPE__C = 'Exempt'  and  BILL_TO_PARENT__C is Null then 1 
	when CATEGORY_TYPE__C = 'Parent' and (select count(*) from PRODAccounts where BILL_TO_PARENT__C = base.ID ) = (select count(*) from PRODAccounts where BILL_TO_PARENT__C = base.ID and CATEGORY_TYPE__C = 'Exempt' ) then  1 
	else  0 end as IsExempted
from PRODAccounts base ) acc
