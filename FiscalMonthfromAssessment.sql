-- query to make table for saving Billing Entities for the last three years
select 
 ID, 
 [Source Name],
 [Assess Year],
 [Fiscal End Month],
 [Fiscal Start Month],
  IMIS_Service.dbo.fn_TransParentID(base.ID, base.[Assess Year]) as [Billing Entity]
 INTO     BOOMI_DEV.dbo.BilEnt_Assessments


from 
	( 
	select  ID,
			'Assess' as [Source Name],
           case when assess.FISCAL_MONTH != '' then FORMAT(CONVERT(INT,assess.[FISCAL_MONTH]), '00')  else '' end   as [Fiscal End Month],
	       assess.Assess_Year as [Assess Year] ,
		     case when assess.FISCAL_MONTH > 0 and  assess.FISCAL_MONTH < 12  then  FORMAT(CONVERT(INT,assess.Fiscal_Month +1), '00') 
			      when assess.FISCAL_MONTH = 12 then '01' 
                       else '' end as [Fiscal Start Month]
		   from IMIS.dbo.Assess assess where Assess_Year in ('2017/18' , '2018/19','2019/20') 
	) base 	

    ----------------------------------
    -- query to get all tie records --
    ----------------------------------
select 
main.[Billing Entity] as Parent,
bil_ent.ID as Location,
bil_ent.[Assess Year],
bil_ent.[Source Name],
bil_ent.[Fiscal Start Month],
bil_ent.[Fiscal End Month]
 from 
(select * from 
(
select 
[Billing Entity],
dbo.getMaxFiscalMonthfromAssessment([Billing Entity],[Source Name]) as [Fiscal Month]
from
 (select distinct [Billing Entity],[Source Name]
 from  BOOMI_DEV.dbo.BilEnt_Assessments where ID != [Billing Entity]) base )_  where _.[Fiscal Month] = 'tie') main
 LEFT JOIN BOOMI_DEV.dbo.BilEnt_Assessments bil_ent on bil_ent.[Billing Entity] = main.[Billing Entity] 



ALTER FUNCTION dbo.getMaxFiscalMonthfromAssessment(@Parent varchar(255),@source varchar(255) )  
RETURNS VARCHAR(255) as
BEGIN
RETURN (
 select top 1
 case when count([FM count]) over(partition by [FM count] ) > 1 then 'tie' else [Fiscal End Month] end answer from 
 (select top 2 
 [Fiscal End Month] , 
 count([Fiscal End Month]) as [FM count]
 from BOOMI_DEV.dbo.BilEnt_Assessments  where [Billing Entity] = @Parent and [Source Name] = @source
 Group By [Fiscal End Month] )_ ORder By [FM count] DESC)
 End
 go
