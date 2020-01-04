ALTER VIEW [dbo].[VW_IMIS_Roll_up_Revenue] as
    select loc_info.ID as  ID,
	name.CO_ID AS CO_ID
 from IMIS.dbo.Loc_Info    loc_info
 LEFT JOIN IMIS.dbo.Name name on loc_info.ID = name.ID and loc_info.REVENUE_ROLLUP = 1 where name.STATUS != 'D'



Alter VIEW dbo.VW_IMIS_Account_Exempted as
select * from (select  ID, 
 CATEGORY_TYPE__C, 
 TOURISM_ID__C, 
 BILLING_CYCLE__C, 
 IsExempted,
 case
	when IsExempted = 1   then '01' end  as [Fiscal Start Month] ,
 case
	when IsExempted = 1   then '12'  end as [Fiscal End Month] 

 from
 (select 
 ID, 
 CATEGORY_TYPE__C, 
 TOURISM_ID__C, 
 BILLING_CYCLE__C,
case 
	when CATEGORY_TYPE__C = 'Exempt'  and  BILL_TO_PARENT__C is Null then 1 
	when CATEGORY_TYPE__C = 'Parent' and  (select count(*) from PRODAccounts where BILL_TO_PARENT__C = base.ID and CATEGORY_TYPE__C  ='Assessed') = 0 then  1  
	else  0 end as IsExempted
from PRODAccounts base ) acc where IsExempted = 1) _ 