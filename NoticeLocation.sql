ALTER VIEW [dbo].[VW_IMIS_Notice_Location]
AS 
select
dbo.getLetterDate([Assess Year] ,  [Notice Type]  , main.[Billing Entity] ) as [Letter Date],
 [Notice Type], 
 [Current SEQN],
 [Account],
 [Billing Entity],
  [Assess Year]
  from 
(
  select
base.Test as [Letter Date],
case when base.[NoticeType] = 'N7' then 'N6' else base.[NoticeType] end as [Notice Type],
base.SEQN   as [Current SEQN],
base.Id as [Account],
IMIS_Service.dbo.fn_TransParentID(base.Id, base.ASSESS_YEAR)  as [Billing Entity],
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
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.Id =  IMIS_name.ID ) main where main.[Status Flag] !='D' 
GO