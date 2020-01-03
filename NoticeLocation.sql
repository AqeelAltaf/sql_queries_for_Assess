ALTER VIEW [dbo].[VW_IMIS_Notice_Location]
AS 
select
dbo.getLetterDate([Assess Year] ,  [Notice Type]  , main.[Billing Entity] ) as [Letter Date],
 case when [Notice Type] = 'N7' then 'N6' else [Notice Type] end as [Notice Type], 
 [Current SEQN],
 [Account],
 [Billing Entity],
  [Assess Year]
  from 
(
  select
base.Test as [Letter Date],
base.[NoticeType] as [Notice Type],
base.SEQN   as [Current SEQN],
base.Id as [Account],
b_ent.[Billing Entity] as [Billing Entity], 
base.ASSESS_YEAR as [Assess Year],
IMIS_name.STATUS as [Status Flag]

 from 
 ( 
     select *
--  id,SEQN,Notice_Type,Test
FROM IMIS.dbo.Assess_Notice 
unpivot
(
  Test
  for  NoticeType in (AQ1,AQ2,AQ3,N1,N2,N3,N4,N5,N6,N7,B1,B2,B3,B4,B5,A1,A2,A3)
) as NoticeType  ) base
LEFT JOIN BOOMI_DEV.dbo.VW_Billing_Entity b_ent  on b_ent.Id = base.ID and b_ent.ASSESS_YEAR = base.ASSESS_YEAR
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.Id =  IMIS_name.ID where IMIS_name.[Status] != 'D' ) main  
 LEFT JOIN IMIS.dbo.Name IMIS_name on main.[Billing Entity] =  IMIS_name.ID where IMIS_name.[Status] != 'D' 
GO