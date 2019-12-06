----------------- Notes ----------------- 
--  All of the validation queries are directly written in IMIS tables.  
--  In queries of Assess Objects , I've joinned with names table to exclude records with status 'D'
--  IMIS_to_sf_seg_map : this is the table  in which I've saved Segment Code's mapping from IMIS to salesforce. 


-----------------------------------------
            --=================================--
-- What:  Assess records
-- Values: total gross revenue, assessment due, count of Assess
-- How: By segment (from assess) and Assess year.
-- Result: All values match from each system
-- confusions/things to ask : what is assessment_due?? s it assessment Cal??


--- from our view  (this for validation from intermediate view , you can ignore this as I've provide same query on table )
select [Assess Year],
       [Segment Code], 
       count(*) as [count of Assess], 
       sum([Primary Gross Revenue]+[Secondary Assessment Rate]) as [total gross revenue]
from BOOMI_DEV.dbo.VW_IMIS_Assess Group By [Assess Year], [Segment Code]

-- total gross revenue, count of Assess  from IMIS tables
select [Assess Year],
 [Segment Category],
 count(*) as [count] ,
 sum([Gross Revenue]) as [Total Gross Revenue] from 
(
	select  * from (
 
	select assess.Assess_Year as [Assess Year],
	COALESCE(imis_seg_map.value_in_salesforce, acc.Segment_Code__C) as [Segment Code],
	COALESCE(imis_seg_map.category, acc.Segment_Category__C) as [Segment Category],
	assess.GROSS_RECEIPTS + assess.S_GROSS_REVENUE  + assess.SECSEG_GROSSRECEIPTS as [Gross Revenue],
	IMIS_name.Status  as [Status] from IMIS.dbo.Assess assess
	LEFT JOIN IMIS.dbo.Name IMIS_name on assess.ID =  IMIS_name.ID
	LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  assess.segment = LTRIM(imis_seg_map.code_in_imis)
	LEFT JOIN BOOMI_DEV.dbo.PRODAccounts acc ON assess.ID = acc.TOURISM_ID__C )
base where base.Status != 'D' and  base.[Assess Year] != '' ) main GROUP BY [Assess Year], [Segment Category]


-- total assessment due  from IMIS tables
select [Assess Year],
 [Segment Category],
 sum([IMIS Assessment Calculation]) as [Assessment Due]
  from 
(
	select  * from (
 
	select assess.Assess_Year as [Assess Year],
	COALESCE(imis_seg_map.value_in_salesforce, acc.Segment_Code__C) as [Segment Code],
	COALESCE(imis_seg_map.category, acc.Segment_Category__C) as [Segment Category],
	case when assess.Exempt_Code not in  ('','NOTOUR','UNDER1') then  assess.ASSESSMENT_CALC  else  0  end as [IMIS Assessment Calculation],
	assess.IsPaid as [IsPaid],
	IMIS_name.Status  as [Status] from IMIS.dbo.Assess assess
	LEFT JOIN IMIS.dbo.Name IMIS_name on assess.ID =  IMIS_name.ID
	LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  assess.segment = LTRIM(imis_seg_map.code_in_imis)
	LEFT JOIN BOOMI_DEV.dbo.PRODAccounts acc ON assess.ID = acc.TOURISM_ID__C  )
base where base.IsPaid = 0 and base.Status != 'D' and  base.[Assess Year] != '' ) main GROUP BY [Assess Year], [Segment Category]



-- from our view  (this for validation from intermediate view , you can ignore this as I've provide same query on table )
select sum([IMIS Assessment Calculation]) from BOOMI_DEV.dbo.[VW_IMIS_rev_Assess] where [IMIS IsPaid] = 0



 
        --=================================--
--What: Notices from previous years (2018/19)
--Values: Count of notices
--How: by year by notice number
--Result: Counts must be the same in both systems
--confusions/things to ask : Notice Number means Notice Type?? do we need to fetch 2018/19 records ?


-- from IMIS table 

 select NoticeType , count(*) as [Count of notices] from
 (select 
 case when base.NoticeType = 'N7' then 'N6' else base.NoticeType end as NoticeType
  from  
 ( 
     select *
FROM IMIS.dbo.Assess_Notice 
unpivot
(
  Test
  for  NoticeType in (AQ1,AQ2,AQ3,N1,N2,N3,N4,N5,N6,N7,B1,B2,B3,B4,B5,A1,A2,A3)
) as NoticeType  ) base  LEFT JOIN IMIS.dbo.Name IMIS_name on base.ID =  IMIS_name.ID
 where   ASSESS_YEAR ='2018/19' and IMIS_name.STATUS != 'D' ) main  Group By NoticeType 

-- from our view 

        --=================================--
-- What: Notices to be produced
-- Values: January billing cycle
-- How: Number of notices by segment by type(BIL or LOC)
-- Result: Counts must be the same in both systems
-- confusions/things to ask : 

-- for BIL
select SEGMENT_CATEGORY__C, BILLING_CYCLE__C, NoticeType,[Billing Entity],  count(*) as [Count of Notices] from 
( select  acc.SEGMENT_CATEGORY__C, acc.BILLING_CYCLE__C, 
case when base.NoticeType = 'N7' then 'N6' else base.NoticeType end as NoticeType ,
 base.[Billing Entity]  from
 ( 
     select IMIS_Service.dbo.fn_TransParentID(Id, ASSESS_YEAR)  as [Billing Entity],*

FROM IMIS.dbo.Assess_Notice 
unpivot
(
  Test
  for  NoticeType in (AQ1,AQ2,AQ3,N1,N2,N3,N4,N5,N6,N7,B1,B2,B3,B4,B5,A1,A2,A3)
) as NoticeType  ) base
 LEFT JOIN BOOMI_DEV.dbo.PRODAccounts acc ON base.ID = acc.TOURISM_ID__C
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.ID =  IMIS_name.ID
 where acc.BILLING_CYCLE__C ='January' and IMIS_name.STATUS != 'D') main Group by SEGMENT_CATEGORY__C, BILLING_CYCLE__C, NoticeType, [Billing Entity]

-- for child/ Account / Loc

select SEGMENT_CATEGORY__C , BILLING_CYCLE__C ,NoticeType ,ID, count(*) as [Count of Notices] from  (
select acc.SEGMENT_CATEGORY__C, acc.BILLING_CYCLE__C,  base.ID, 
case when base.NoticeType = 'N7' then 'N6' else base.NoticeType end as NoticeType 
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
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.ID =  IMIS_name.ID
 where acc.BILLING_CYCLE__C ='January' and IMIS_name.STATUS != 'D' ) main Group by SEGMENT_CATEGORY__C, BILLING_CYCLE__C, NoticeType, ID


        --=================================--
-- What: renewal date (similar to notice count)
-- Values: Count of LOCs
-- How: By segment, by date, by status
-- Results: Counts must be the same in both systems
-- confusions/things to ask/notes : this column is not ready yet , will do it later 




        --=================================--
-- What: Filed unpaid
-- Values: Assessment Due, Count
-- How: by segment, by year(filing for year)
-- Results: Count of Locations must match, Sum of assessment due must match

select [Assess Year],
 [Segment Code],
 count(*),
 sum([IMIS Assessment Calculation]) as [Assessment Due]
  from 
(
	select  * from (
 
	select assess.Assess_Year as [Assess Year],
	COALESCE(imis_seg_map.value_in_salesforce, acc.Segment_Code__C) as [Segment Code],
	case when assess.Exempt_Code not in  ('','NOTOUR','UNDER1') then  assess.ASSESSMENT_CALC  else  0  end as [IMIS Assessment Calculation],
	Format(assess_notice.N_FILEDATE,'MM/dd/yyyy') as [Filed Date],
	assess.IsPaid as [IsPaid],
	IMIS_name.Status  as [Status] from IMIS.dbo.Assess assess
	LEFT JOIN IMIS.dbo.Name IMIS_name on assess.ID =  IMIS_name.ID
	LEFT JOIN IMIS.dbo.Assess_Notice assess_notice on assess.ID = assess_notice.ID and assess.ASSESS_YEAR = assess_notice.ASSESS_YEAR
	LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  assess.segment = LTRIM(imis_seg_map.code_in_imis)
	LEFT JOIN BOOMI_DEV.dbo.PRODAccounts acc ON assess.ID = acc.TOURISM_ID__C  )
base where base.IsPaid = 'False' and base.Status != 'D' and  base.[Assess Year] != '' and [Filed Date] != '') main GROUP BY [Assess Year], [Segment Code]


        --=================================--
-- What: off cycle notices (not part of Jan cycle)
-- Values: Counts
-- How: LOCS by segment by notice number
-- Results: Counts must be the same in both systems




select SEGMENT_CATEGORY__C , BILLING_CYCLE__C ,NoticeType ,ID, count(*) as [Count of Notices] from  (
select acc.SEGMENT_CATEGORY__C, acc.BILLING_CYCLE__C,  base.ID, 
case when base.NoticeType = 'N7' then 'N6' else base.NoticeType end as NoticeType 
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
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.ID =  IMIS_name.ID
 where acc.BILLING_CYCLE__C !='January' and IMIS_name.STATUS != 'D' ) main Group by SEGMENT_CATEGORY__C, BILLING_CYCLE__C, NoticeType, ID

        --=================================--
-- What: Audits for 2018/19 and 2019/20
-- Values: Count of LOCs with an open audit, count of LOCs with closed audits, number of open audits
-- How: by year by audit reason
-- Results: Counts must be the same in both systems (did we change the number of audits?)

-- Audit Checked  = True closed else open
-- things to ask: is me AuditReson sab ke null arhe hain

select [Audit Status] , [Audit Reason Note], [AuditYear], count(*) as [Audit Count] 
 (select 
[AuditYear],
case when AuditChecked = 0 then  'Open' 
	when AuditChecked = 1 then 'Closed'  end as [Audit Status],
	LowTNT_Note + BalanceDue_Note+ DecreaseRevenue_Note + DecreaseTNT_Note + RepeatRevenue_Note + RoundedRevenue_Note + NoTNT_Note + NoSecondTNT_note + Below1mil_note as [Audit Reason Note] 
	from IMIS.dbo.Assess_Audit) base group by [Audit Status] , [Audit Reason Note] , [AuditYear]


        --=================================--
-- What: Active and exempt locations
-- Values: count of active standalone LOCs, count of BILs, count of all active locations, count of all exempt LOCs
-- How: by segment
-- Results: Counts must be the same in both systems




-- active standalone LOCs : where Status = 'A' and Member Type in ('LOC', 'RL')
-- BILs : where Status = 'A' and Member Type in ('BIL', 'RB')
-- active locations : locations which are not Bakrupt or Archiive are Active Locations 
-- exempt Locations :  Member_Type = Loc/RL , Name.status = E,IP,IF,I,NA and HasFilledEver = true
-- Archive : 	Member_Type = LOC/RL/BIL , status = R
-- Bankcruptcy :	Name. status = CH7/CH11 Memeber_type = BIL/RB/LOC


-- query for Count of 'Exempt' , 'Active Standalone LOCs' and Bils
   select Type, count(Type) from 
(
select Category, Status, 
case when Status = 'A' and Category in ('LOC', 'RL') then 'Active Standalone LOCs'
	 when Status = 'A' and Category in ('BIL', 'RB') then 'BILs' 
	 when Status in ('E','IP','IF','I','NA') and Category in ('LOC', 'RL')  and Has_Filed_Ever = 1  then 'Exempt'
	 else '' 
end as [Type] 
   from  [BOOMI].[dbo].[vIMIS_Name]) base   where base.Type in ('Active Standalone LOCs','BILs' , 'Exempt') group by Type


-- for count of Active location 
select Type,
 count(Type) from 

(
select Category, Status, 
case when Status != 'R' and Category not in ('BIL', 'LOC','RL') then 'Active Location' 
	 when Status not in ('CH7','CH11') and Category not in ('BIL', 'RB','LOC')   then 'Active Location'
	 else '' 
end as [Type] 
   from  [BOOMI].[dbo].[vIMIS_Name]) base   where base.Type in ('Active Location') group by Type



        --=================================--
-- What: All LOCs by region
-- Values: Counts
-- How: by region
-- Results: Counts must be the same in both systems

   select dist.LiaisonDistrict , count(ID) as [Number of Location] from IMIS.dbo.Name_Address name_addr  
   LEFT JOIN 
  ( select * from (
select *,  ROW_NUMBER() OVER(PARTITION BY LiaisonDistrict , ZipCode, ZIP Order By ZipCode ) as [RN] from IMIS.dbo.vLiaisonDistrict   ) l_dsit where RN = 1 ) dist on name_addr.ZIP =   dist.ZIP  where name_addr.ZIP !=  '' GROUP BY  dist.LiaisonDistrict 



        --=================================--
-- What: Previous year's revenue
-- Values : $$amounts
-- How: By segment by year
-- Results: Amounts must match in both systems
-- assessment calc


select [Assess Year],
 [Segment Category],
 sum([IMIS Assessment Calculation]) as [Assessment Due]
  from 
(
	select  * from (
 
	select assess.Assess_Year as [Assess Year],
	COALESCE(imis_seg_map.value_in_salesforce, acc.Segment_Code__C) as [Segment Code],
	COALESCE(imis_seg_map.category, acc.Segment_Category__C) as [Segment Category],
	case when assess.Exempt_Code not in  ('','NOTOUR','UNDER1') then  assess.ASSESSMENT_CALC  else  0  end as [IMIS Assessment Calculation],
	IMIS_name.Status  as [Status] from IMIS.dbo.Assess assess
	LEFT JOIN IMIS.dbo.Name IMIS_name on assess.ID =  IMIS_name.ID
	LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  assess.segment = LTRIM(imis_seg_map.code_in_imis)
	LEFT JOIN BOOMI_DEV.dbo.PRODAccounts acc ON assess.ID = acc.TOURISM_ID__C  )
base where base.Status != 'D' and  base.[Assess Year] != '' and base.[Assess Year] != '2018/19' ) main GROUP BY [Assess Year], [Segment Category]