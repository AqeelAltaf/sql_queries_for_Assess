ALTER VIEW dbo.VW_IMIS_Assess_Notice_Int
AS
select 
--SUBSTRING( concat(main.[External Id],'-',main.[Notice Type],'-',NewID()), 0, 19 ) as [External Id],
main.[External Id],
main.[Account] ,
main.[Assess Year],
-- when the record is itself's parent or have no parent then it's Bill To 
case when  main.[Billing Entity]  in (main.Account,'')  then 1 else 0 end as [Is Bill To],
main.[Deadline],
main.[Letter Date],
main.[Billing Entity],
case when main.[Notice Type] = 'N7' then 'N6' else main.[Notice Type]  end as [Notice Type],
main.[Letter Status],
case when main.[Notice Type] in ('N1','N2','N3','N4','N5','N6','N7') and main.Max_N_File_Date != 'NULL' and main.[Letter Date] = main.Max_N_File_Date then  main.[Notice Drop Date]
 when main.[Notice Type] in ('B1','B2','B3','B4','B5') and main.Max_N_File_Date != 'NULL' and main.[Letter Date] = main.Max_N_File_Date then  main.[Notice Drop Date]
 when main.[Notice Type] in ('A1','A2','A3') and main.Max_N_File_Date != 'NULL' and main.[Letter Date] = main.Max_N_File_Date then  main.[Notice Drop Date]
 when main.[Notice Type] in ('AQ1','AQ2','AQ3') and main.Max_N_File_Date != 'NULL' and main.[Letter Date] = main.Max_N_File_Date then  main.[Notice Drop Date]
else '' end as [Notice Drop Date],

--main.[Notice Drop Date],
main.[7% Decrease in Revenue],
main.[7 Point Decrease in TNT],
main.[Clear 7% Decrease in Revenue],
main.[Clear 7 Point Decrease in TNT],
main.[Clear Low TNT Reported],
main.[Clear Repeated Revenue],
main.[Clear Rounded Revenue],
main.[Clear Secondary TNT],
main.[Clear Zero TNT],
main.[Low TNT Reported],
main.[Repeated Revenue],
main.[Rounded Revenue],
main.[Secondary TNT],
main.[Zero TNT],
main.[Segment],
main.[Segment Code],
rates.RATE__C as [Segment Rate],
convert(numeric(10,2), seg_max.RATE__C) as [Segment Max] ,

-- this is for NOtice Timeline date which is extrated from Billing Period Table
case when main.[Notice Type] = 'N1' then   format(billing_period.[N1_END_DATE__C],'MM/dd/yyyy')
  when main.[Notice Type] = 'N2' then      format(billing_period.[N2_END_DATE__C],'MM/dd/yyyy')
  when main.[Notice Type] = 'N3' then      format(billing_period.[N3_END_DATE__C],'MM/dd/yyyy')
  when main.[Notice Type] = 'N4' then      format(billing_period.[N4_END_DATE__C],'MM/dd/yyyy')
  when main.[Notice Type] = 'N5' then      format(billing_period.[N5_END_DATE__C],'MM/dd/yyyy')
  when main.[Notice Type] = 'N6' or main.[Notice Type] = 'N7'  then   FORMAT(billing_period.[N6_END_DATE__C],'MM/dd/yyyy')
  when main.[Notice Type] = 'AQ1' then    format(billing_period.[AQ1_END_DATE__C],'MM/dd/yyyy')
  when main.[Notice Type] = 'AQ2' then    format(billing_period.[AQ2_END_DATE__C],'MM/dd/yyyy')
  when main.[Notice Type] = 'AQ3' then    format(billing_period.[AQ3_END_DATE__C],'MM/dd/yyyy')
  else '' end as [Notice Timeline Date],

case when main.[Notice Type] in ('N1','N2','N3','N4','N5','N6','N7') and main.Max_N_File_Date != '' and main.[Letter Date] = main.Max_N_File_Date then  format(main.[IMIS Notice File Date],'MM/dd/yyyy') else '' end as [IMIS Notice File Date]
 from 
 (
   select

--

-- this is temporary column only for saving maximum date
case when base.[NoticeType] in ('N1','N2','N3','N4','N5','N6','N7')
 then format(COALESCE(assess_notice1.N7,assess_notice1.N6,assess_notice1.N5,assess_notice1.N4,assess_notice1.N3,assess_notice1.N2,assess_notice1.N1),'MM/dd/yyyy') 
when base.[NoticeType] in ('A3','A2','A1')
 then format(COALESCE(assess_notice1.A3,assess_notice1.A2,assess_notice1.A1),'MM/dd/yyyy') 
when base.[NoticeType] in ('AQ3','AQ2','AQ1')
 then format(COALESCE(assess_notice1.AQ3,assess_notice1.AQ2,assess_notice1.AQ1),'MM/dd/yyyy') 
when base.[NoticeType] in ('B5','B4','B3','B2','B1')
 then format(COALESCE(assess_notice1.B5,assess_notice1.B4,assess_notice1.B3,assess_notice1.B2,assess_notice1.B1),'MM/dd/yyyy') 
 else 'NULL' end as Max_N_File_Date,
-- this is the Notice File date which is to be appended in the the latest notice 
base.N_FILEDATE as [IMIS Notice File Date], 

-- these are brought from the Assess_Audit
ass_aud.DecreaseRevenue as [7% Decrease in Revenue],	

ass_aud.DecreaseTNT as [7 Point Decrease in TNT],
case when ass_aud.DecreaseRevenue_Cleared != '' then 1 else 0 end as [Clear 7% Decrease in Revenue],
case when ass_aud.DecreaseTNT_Cleared != '' then 1 else 0 end as [Clear 7 Point Decrease in TNT],
case when ass_aud.LowTNT_Cleared != '' then 1 else 0  end as  [Clear Low TNT Reported],
case when ass_aud.RepeatRevenue_Cleared != '' then 1 else 0 end as [Clear Repeated Revenue],
ass_aud.RoundedRevenue_Cleared as  [Clear Rounded Revenue],
ass_aud.NoSecondTNT_Cleared as [Clear Secondary TNT],
ass_aud.NoTNT_Cleared as [Clear Zero TNT],
ass_aud.LowTNT as [Low TNT Reported], 
ass_aud.RepeatRevenue as [Repeated Revenue],
ass_aud.RoundedRevenue as [Rounded Revenue],
ass_aud.NoSecondTNT as [Secondary TNT],
ass_aud.NoTNT as [Zero TNT],

-- new columns, these are brought from account table
acc.SEGMENT_CATEGORY__C as [Segment],
acc.SEGMENT_CODE__C as [Segment Code],
acc.BILLING_CYCLE__C as [Bill Cycle],


IMIS_name.STATUS as [Status Flag],
-- calling function to get value of Account/ID of the record by the function(given by faiza) 
IMIS_Service.dbo.fn_TransParentID(base.Id, base.ASSESS_YEAR)  as [Billing Entity], 

-- Use external id to populate this field
base.Id as [Account],
 base.ASSESS_YEAR as [Assess Year],

  -- this is old logic of is Bill To
 --Search [IMIS].[dbo].[Assess_Notice]. Id in all accounts.Once account found check its field bill to parent.If bill to parent is blank then mark this checkbox true else keep it false.
 --case when acc.BILL_TO_PARENT__C is  null then  'True' else 'False' end as [Is Bill To],
 case 
 when base.NoticeType >= 'A1' and base.[NoticeType] <='A3' and base.[A_DUEDATE] is  not null then FORMAT(base.A_DUEDATE,'MM/dd/yyyy')
 when base.NoticeType >= 'N1' and base.[NoticeType] <='N7' and base.[N_ACCRUEDATE] is  not null then FORMAT(base.N_ACCRUEDATE,'MM/dd/yyyy')
 when base.NoticeType >= 'B1' and base.[NoticeType] <='B5' and base.[B_ACCRUEDATE] is  not null then FORMAT(base.B_ACCRUEDATE,'MM/dd/yyyy')
 --when base.NoticeType >= 'AQ1' and base.[NoticeType] <='AQ3' and base.AQ_DROPDATE is  not null then FORMAT(base.AQ_DROPDATE,'MM/dd/yyyy')
 else ''
 end as [Deadline],
 format(base.test ,'MM/dd/yyyy') as [Letter Date],
 'Sent' as [Letter Status],
 base.[NoticeType] as [Notice Type],
  case 
 when base.NoticeType >= 'A1' and base.[NoticeType] <='A3' and base.A_dropDate is  not null then FORMAT(base.A_dropDate,'MM/dd/yyyy')
 when base.NoticeType >= 'N1' and base.[NoticeType] <='N7' and base.N_DROPDATE is  not null then FORMAT(base.N_DROPDATE,'MM/dd/yyyy')
 when base.NoticeType >= 'B1' and base.[NoticeType] <='B5' and base.B_DROPDATE is  not null then FORMAT(base.B_DROPDATE,'MM/dd/yyyy')
 when base.NoticeType >= 'AQ1' and base.[NoticeType] <='AQ3' and base.AQ_DROPDATE is  not null then FORMAT(base.AQ_DROPDATE,'MM/dd/yyyy')
 else ''
 end as [Notice Drop Date] ,
 base.seqn as [External Id]
 from 
( select *
--  id,SEQN,Notice_Type,Test
FROM IMIS.dbo.Assess_Notice 
unpivot
(
  Test
  for  NoticeType in (AQ1,AQ2,AQ3,N1,N2,N3,N4,N5,N6,N7,B1,B2,B3,B4,B5,A1,A2,A3)
) as NoticeType  ) base
LEFT JOIN IMIS.dbo.Assess_Notice assess_notice1 on base.SEQN = assess_notice1.SEQN   
 LEFT JOIN BOOMI_DEV.dbo.PRODAccounts acc ON base.ID = acc.TOURISM_ID__C
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.ID =  IMIS_name.ID
LEFT JOIN IMIS.dbo.Assess_Audit ass_aud on base.[NoticeType] in ('A1','A2','A3')   and base.Id = ass_aud.ID and base.[ASSESS_YEAR]  = ass_aud.AuditYear ) main 
LEFT JOIN BOOMI_DEV.dbo.SegmentRate rates on main.[Assess Year] = rates.[AssessYear] and main.[Segment] = rates.[SegmentCategory] 
LEFT JOIN BOOMI_DEV.dbo.SegmentMax seg_max on main.[Assess Year] = seg_max.[PreviousFiscalYear] and main.[Segment Code] = seg_max.[SEGMENT_CODE__C] 
LEFT JOIN BOOMI_DEV.dbo.BillingPeriod billing_period on main.[Notice Type] in ('N1','N2','N3','N4','N5','N6','N7','AQ1','AQ2','AQ3') and main.[Assess Year]  = billing_period.ASSESS_YEAR__C and main.[Bill Cycle] =  billing_period.BILL_CYCLE__C 
where main.[Status Flag] != 'D' ;