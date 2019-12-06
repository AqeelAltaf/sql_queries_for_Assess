-- Assess Notice me se wo billing Entities laani hain jin pr ek jesi notice type k ek se ziada date pr letters  gaye hon ek hi year me 
Select base.[Assess Year],
base.[Billing Entity],
base.[Notice Type],
not_loc.[Account] , 
not_loc.[Letter Date] 
from (
	Select 
	[Billing Entity]  ,
	[Assess Year] , 
	[Notice Type]  , 
	count(*) AS LetterDateCount 
	from dbo.temp_Notice_Location 
	Group By  [Billing Entity]  ,[Assess Year] , [Notice Type] having count(distinct [Letter Date]) > 1) base
 LEFT JOIN dbo.temp_Notice_Location  not_loc 
 on base.[Assess Year] = not_loc.[Assess Year] and base.[Billing Entity] = not_loc.[Billing Entity] and base.[Notice Type] = not_loc.[Notice Type] order by base.[Billing Entity],base.[Assess Year]



-- query from direct table , for Billing Entitty 
select  [Notice Type] ,[Assess Year], [Billing Entity]  from 
(select 	IMIS_Service.dbo.fn_TransParentID(base.Id, base.ASSESS_YEAR)  as [Billing Entity]  ,
	[Assess_Year]  as [Assess Year], 
case when base.NoticeType = 'N7' then 'N6' else base.NoticeType end as [Notice Type] , 
base.Test  as [Letter Date]
  from 
 ( 
     select *
FROM IMIS.dbo.Assess_Notice 
unpivot
(
  Test
  for  NoticeType in (AQ1,AQ2,AQ3,N1,N2,N3,N4,N5,N6,N7,B1,B2,B3,B4,B5,A1,A2,A3)
) as NoticeType  ) base
 LEFT JOIN BOOMI_DEV.dbo.PRODAccounts acc ON base.ID = acc.TOURISM_ID__C
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.ID =  IMIS_name.ID where IMIS_name.STATUS  !='D' ) main   Group By [Notice Type] ,[Assess Year], [Billing Entity] having count(distinct [Letter Date]) > 1



