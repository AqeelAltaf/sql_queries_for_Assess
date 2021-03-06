ALTER VIEW dbo.VW_IMIS_Assess_Notice As
select [External Id],
[Account] ,
[Assess Year],
 [Is Bill To],
[Deadline],
[Letter Date],
[Billing Entity],
 [Notice Type],
[Letter Status],
[Notice Drop Date],
[7% Decrease in Revenue],
[7 Point Decrease in TNT],
[Clear 7% Decrease in Revenue],
[Clear 7 Point Decrease in TNT],
[Clear Low TNT Reported],
[Clear Repeated Revenue],
[Clear Rounded Revenue],
[Clear Secondary TNT],
[Clear Zero TNT],
[Low TNT Reported],
[Repeated Revenue],
[Rounded Revenue],
[Secondary TNT],
[Zero TNT],
[Segment],
[Segment Code],
[Segment Rate],
[Segment Max] ,
[Notice Timeline Date],
[IMIS Notice File Date]
 from  (select  *,
RANK() OVER(PARTITION By [Assess Year], [Billing Entity], [Notice Type] ORDER BY Account) as RowNumber from dbo.VW_IMIS_Assess_Notice_Int) base where base.RowNumber =1 