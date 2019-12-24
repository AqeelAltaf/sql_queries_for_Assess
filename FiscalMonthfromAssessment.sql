-- query to make table for saving Billing Entities for the last three years
select 
 ID, 
 [Source Name],
 [Assess Year],
 [Fiscal End Month],
 [Fiscal Start Month],
 IMIS_Service.dbo.fn_TransParentID(base.ID, base.[Assess Year]) as [Billing Entity],
 Superseded,
 [Bill Cycle],
 case when [Bill Cycle] =  'January' then  '2018/19' else '2019/20' end as [Target Assess Year] 
 INTO  BOOMI_DEV.dbo.BilEnt_Assessments
from 
	( 
	select acc.BILLING_CYCLE__C as [Bill Cycle], 
	         assess.ID,
			'Assess' as [Source Name],
			Superseded,
           case when assess.FISCAL_MONTH != '' then FORMAT(CONVERT(INT,assess.[FISCAL_MONTH]), '00')  else '' end   as [Fiscal End Month],
	       assess.Assess_Year as [Assess Year] ,
		     case when assess.FISCAL_MONTH > 0 and  assess.FISCAL_MONTH < 12  then  FORMAT(CONVERT(INT,assess.Fiscal_Month +1), '00') 
			      when assess.FISCAL_MONTH = 12 then '01' 
                       else '' end as [Fiscal Start Month]
		   from IMIS.dbo.Assess assess 
		   LEFT JOIN  BOOMI_DEV.dbo.PRODAccounts acc ON assess.ID = acc.TOURISM_ID__C 
		   where assess.Assess_Year in ( '2018/19','2019/20') 
	) base 
    ----------------------------------
    -- query to get all tie records --
    ----------------------------------
select 
main.[Billing Entity] as Parent,
main.[Fiscal Month],
bil_ent.ID as Location,
bil_ent.[Assess Year],
bil_ent.[Source Name],
bil_ent.[Fiscal Start Month],
bil_ent.[Fiscal End Month],
bil_ent.[Bill Cycle]
from 
(select * from 
(
select 
[Billing Entity],
dbo.getMaxFiscalMonthfromAssessment([Billing Entity],[Bill Cycle]) as [Fiscal Month],
[Target Assess Year]
from
 (select distinct [Billing Entity],[Bill Cycle],[Target Assess Year]
 from  BOOMI_DEV.dbo.BilEnt_Assessments where ID != [Billing Entity]) base )_ 
  where _.[Fiscal Month] = 'tie'
  ) main
 LEFT JOIN BOOMI_DEV.dbo.BilEnt_Assessments bil_ent on bil_ent.[Billing Entity] = main.[Billing Entity]  and main.[Target Assess Year] = bil_ent.[Assess Year]

 ORDER BY Parent


------------------------------------------------------------------
-----------------------------FUNCTION-----------------------------
------------------------------------------------------------------

ALTER FUNCTION dbo.getMaxFiscalMonthfromAssessment(@Parent varchar(255),@bill_cycle varchar(255) )  
RETURNS VARCHAR(255) as
BEGIN

DECLARE @assess_year varchar(255);
IF @bill_cycle = 'January'
       SET @assess_year =   '2018/19';
ELSE 
       SET @assess_year = '2019/20';

RETURN (
select top 1
 case when count([FM count]) over(partition by [FM count] ) > 1 then 'tie' else [Fiscal End Month] end  from 
 (select top 2 
 [Fiscal End Month] , 
 count([Fiscal End Month]) as [FM count]
 from BOOMI_DEV.dbo.BilEnt_Assessments  where [Billing Entity] = @Parent and [Assess Year] = @assess_year and [Fiscal End Month]!= '' and Superseded = 0
 Group By [Fiscal End Month] )_ ORder By [FM count] DESC)
 End
 go


    --------------------------------------
    -- query to get all non tie records --
    --------------------------------------
Alter VIEW dbo.VW_IMIS_ParFiscalMonth as
select 
main.[Billing Entity] as Parent,
main.[Fiscal Month],
bil_ent.ID as Location,
bil_ent.[Assess Year],
bil_ent.[Source Name],
bil_ent.[Fiscal Start Month],
bil_ent.[Fiscal End Month],
bil_ent.[Bill Cycle]
from 
(select * from 
(
select 
[Billing Entity],
dbo.getMaxFiscalMonthfromAssessment([Billing Entity],[Bill Cycle]) as [Fiscal Month],
[Target Assess Year]
from
 (select distinct [Billing Entity],[Bill Cycle],[Target Assess Year]
 from  BOOMI_DEV.dbo.BilEnt_Assessments where ID != [Billing Entity]) base )_ 
  where _.[Fiscal Month] != 'tie'
  ) main
 LEFT JOIN BOOMI_DEV.dbo.BilEnt_Assessments bil_ent on bil_ent.[Billing Entity] = main.[Billing Entity]  and main.[Target Assess Year] = bil_ent.[Assess Year]

