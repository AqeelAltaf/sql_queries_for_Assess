CREATE VIEW [dbo].[VW_IMIS_Notice_Location_Changes]
AS 
-- Changes view made by aqeel.altaf@gettectonic.com
select
SYS_CHANGE_OPERATION, SYS_CHANGE_VERSION ,
dbo.getLetterDate([Assess Year] ,  [Notice Type]  , main.[Billing Entity] ) as [Letter Date],
 case when [Notice Type] = 'N7' then 'N6' else [Notice Type] end as [Notice Type], 
 [Current SEQN],
 [Account],
 [Billing Entity],
  [Assess Year]

  from 
(
  select
  SYS_CHANGE_OPERATION, SYS_CHANGE_VERSION ,
base.Test as [Letter Date],
base.[NoticeType] as [Notice Type],
base.SEQN   as [Current SEQN],
base.[IMIS Account Number] as [Account],
IMIS_Service.dbo.fn_TransParentID(base.[IMIS Account Number], base.ASSESS_YEAR)  as [Billing Entity],
base.ASSESS_YEAR as [Assess Year],
IMIS_name.STATUS as [Status Flag]

 from 
 ( 
     select *
--  id,SEQN,Notice_Type,Test
FROM BOOMI.dbo.vIMIS_Assess_Notice_CHANGES 
unpivot
(
  Test
  for  NoticeType in (AQ1,AQ2,AQ3,N1,N2,N3,N4,N5,N6,N7,B1,B2,B3,B4,B5,A1,A2,A3)
) as NoticeType  ) base
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.[IMIS Account Number] =  IMIS_name.ID ) main where main.[Status Flag] !='D' 

GO
