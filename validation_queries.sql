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
	assess.Superseded,
	assess.READY_TO_POST,
	COALESCE(imis_seg_map.value_in_salesforce, acc.Segment_Code__C) as [Segment Code],
	COALESCE(imis_seg_map.category, acc.Segment_Category__C) as [Segment Category],
	assess.GROSS_RECEIPTS + assess.S_GROSS_REVENUE  + assess.SECSEG_GROSSRECEIPTS as [Gross Revenue],
	IMIS_name.Status  as [Status] from IMIS.dbo.Assess assess
	LEFT JOIN IMIS.dbo.Name IMIS_name on assess.ID =  IMIS_name.ID
	LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  assess.segment = LTRIM(imis_seg_map.code_in_imis)
	LEFT JOIN BOOMI_DEV.dbo.PRODAccounts acc ON assess.ID = acc.TOURISM_ID__C )
base where base.Status != 'D' and  base.[Assess Year] != '' and base.Superseded = 0  and base.READY_TO_POST = 1 ) main GROUP BY [Assess Year], [Segment Category]


-- total assessment due  from IMIS tables
select 
[Assess Year],
 [Segment Category],
 sum([IMIS Assessment Calculation]) as [Assessment Due],
 count([IMIS Assessment Calculation]) as [Assess Count]
  from 
(
	select  * from (

	select assess.Assess_Year as [Assess Year],
	assess.ID,
	ware_rev.Company,
	COALESCE(imis_seg_map.value_in_salesforce, acc.Segment_Code__C) as [Segment Code],
	COALESCE(imis_seg_map.category, acc.Segment_Category__C) as [Segment Category],
	case when assess.Exempt_Code not in  ('NOTOUR','UNDER1') then  assess.ASSESSMENT_CALC  else  0  end as [IMIS Assessment Calculation],
	assess.[Superseded] as [Superseded],
	assess.READY_TO_POST as READY_TO_POST,
	IMIS_name.Status  as [Status] 
   from IMIS.dbo.Assess assess
	LEFT JOIN IMIS.dbo.Name IMIS_name on assess.ID =  IMIS_name.ID
	LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  assess.segment = LTRIM(imis_seg_map.code_in_imis)
	LEFT JOIN BOOMI_DEV.dbo.PRODAccounts acc ON assess.ID = acc.TOURISM_ID__C  
	LEFT JOIN (select * from BOOMI.[dbo].[vIMIS_Wa rehouse_Revenue] ware_rev_ where ware_rev_.[FOR Assessment Year] in ('2018/19','2019/20') ) ware_rev  on ware_rev.[IMIS Account Number] = assess.ID 
)base  
where base.Company is Null  and base.[IMIS Assessment Calculation] > 0
 and base.[Superseded]  = 0 and base.READY_TO_POST = 1  and base.Status != 'D' and  base.[Assess Year] in ('2018/19','2019/20') ) main 
GROUP BY [Assess Year], [Segment Category]
ORDER BY [Segment Category] , [Assess Year]



-- from our view  (this for validation from intermediate view , you can ignore this as I've provide same query on table )
select sum([IMIS Assessment Calculation]) from BOOMI_DEV.dbo.[VW_IMIS_rev_Assess] where [IMIS IsPaid] = 0



 
        --=================================--
--What: All notices except  2018/19 and 2019/20
--Values: Count of notices
--How: by year by notice number
--Result: Counts must be the same in both systems

-- from IMIS table 

select  
ASSESS_YEAR
,imis_seg_map.Category as [Segment Category] 
, NoticeType 
, count(*) as [Count of Notices] 
 from  (
select 
ASSESS_YEAR, 
loc_info.CURRENT_SEGMENT as [Segment Code] ,
base.[Notice Type] as NoticeType ,
ROW_NUMBER() over(partition by  base.ASSESS_YEAR, base.[Billing Entity],NoticeType  order by base.ID)  as rn 
from 
( 
select 
_.*, 
case when _.NoticeType = 'N7' then 'N6' else _.NoticeType end as [Notice Type] ,
b_ent.[Billing Entity] as [Billing Entity]
 
 from 
 ( 
     select *
FROM IMIS.dbo.Assess_Notice 
unpivot
(
  Test
  for  NoticeType in (AQ1,AQ2,AQ3,N1,N2,N3,N4,N5,N6,N7,B1,B2,B3,B4,B5,A1,A2,A3)
) as NoticeType  ) _
 LEFT JOIN BOOMI_DEV.dbo.VW_Billing_Entity b_ent  on b_ent.Id = _.ID and b_ent.ASSESS_YEAR = _.ASSESS_YEAR) base 
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.[Billing Entity] =  IMIS_name.ID
 LEFT JOIN  IMIS.dbo.Loc_Info  loc_info  on loc_info.ID = base.[Billing Entity] 

 where  IMIS_name.STATUS != 'D'  and base.ASSESS_YEAR not in  ('2018/19', '2019/20')
 ) main 
 LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  main.[Segment Code] = LTRIM(imis_seg_map.code_in_imis) 
 where rn = 1
Group by imis_seg_map.Category , NoticeType , ASSESS_YEAR
Order by case when imis_seg_map.Category is null then 1 else 0 end , imis_seg_map.Category  , NoticeType , ASSESS_YEAR 

-- from our view 

        --=================================--
-- What: Notices to be produced
-- Values: January billing cycle
-- How: Number of notices by segment by type(BIL or LOC)
-- Result: Counts must be the same in both systems
------------------------------------------------------
-- for BIL
------------------------------------------------------

-------------==============================-----------
-- N NOtice for 2018/19 January Cycle
-------------==============================-----------
select  
imis_seg_map.Category as [Segment Category] , NoticeType , count(*) as [Count of Notices] 
 from  (
select 
loc_info.CURRENT_SEGMENT as [Segment Code] ,
base.[Notice Type] as NoticeType ,
ROW_NUMBER() over(partition by NoticeType , base.ASSESS_YEAR, base.[Billing Entity] order by base.ID)  as rn 
from 
( 
select 
_.*, 
case when _.NoticeType = 'N7' then 'N6' else _.NoticeType end as [Notice Type] ,
b_ent.[Billing Entity] as [Billing Entity]
 
 from 
 ( 
     select *
FROM IMIS.dbo.Assess_Notice 
unpivot
(
  Test
  for  NoticeType in (N1,N2,N3,N4,N5,N6,N7)
) as NoticeType  ) _
 LEFT JOIN BOOMI_DEV.dbo.VW_Billing_Entity b_ent  on b_ent.Id = _.ID and b_ent.ASSESS_YEAR = _.ASSESS_YEAR) base 
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.[Billing Entity] =  IMIS_name.ID
 LEFT JOIN BOOMI.dbo.vIMIS_Name  v_name on base.[Billing Entity] = v_name.[IMIS Account Number] 
 LEFT JOIN  IMIS.dbo.Loc_Info  loc_info  on loc_info.ID = base.[Billing Entity] 

 where v_name.[Billing Cycle] like 'jan%' and IMIS_name.STATUS != 'D'  and base.ASSESS_YEAR = '2018/19'
 ) main 
 LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  main.[Segment Code] = LTRIM(imis_seg_map.code_in_imis) 
 where rn = 1
Group by imis_seg_map.Category , NoticeType 
Order by imis_seg_map.Category , NoticeType

-------------==============================-----------
-- N NOtice for 2018/19 July Cycle
-------------==============================-----------
select  
imis_seg_map.Category as [Segment Category] , NoticeType , count(*) as [Count of Notices] 
 from  (
select 
loc_info.CURRENT_SEGMENT as [Segment Code] ,
base.[Notice Type] as NoticeType ,
ROW_NUMBER() over(partition by NoticeType , base.ASSESS_YEAR, base.[Billing Entity] order by base.ID)  as rn 
from 
( 
select 
_.*, 
case when _.NoticeType = 'N7' then 'N6' else _.NoticeType end as [Notice Type] ,
b_ent.[Billing Entity] as [Billing Entity]
 
 from 
 ( 
     select *
FROM IMIS.dbo.Assess_Notice 
unpivot
(
  Test
  for  NoticeType in (N1,N2,N3,N4,N5,N6,N7)
) as NoticeType  ) _
 LEFT JOIN BOOMI_DEV.dbo.VW_Billing_Entity b_ent  on b_ent.Id = _.ID and b_ent.ASSESS_YEAR = _.ASSESS_YEAR) base 
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.[Billing Entity] =  IMIS_name.ID
 LEFT JOIN BOOMI.dbo.vIMIS_Name  v_name on base.[Billing Entity] = v_name.[IMIS Account Number] 
 LEFT JOIN  IMIS.dbo.Loc_Info  loc_info  on loc_info.ID = base.[Billing Entity] 

 where v_name.[Billing Cycle] like 'jul%' and IMIS_name.STATUS != 'D'  and base.ASSESS_YEAR = '2018/19'
 ) main 
 LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  main.[Segment Code] = LTRIM(imis_seg_map.code_in_imis) 
 where rn = 1
Group by imis_seg_map.Category , NoticeType 
Order by imis_seg_map.Category , NoticeType

-------------==============================-----------
-- N NOtice for 2019/20 January Cycle
-------------==============================-----------
select  
imis_seg_map.Category as [Segment Category] , NoticeType , count(*) as [Count of Notices] 
 from  (
select 
loc_info.CURRENT_SEGMENT as [Segment Code] ,
base.[Notice Type] as NoticeType ,
ROW_NUMBER() over(partition by NoticeType , base.ASSESS_YEAR, base.[Billing Entity] order by base.ID)  as rn 
from 
( 
select 
_.*, 
case when _.NoticeType = 'N7' then 'N6' else _.NoticeType end as [Notice Type] ,
b_ent.[Billing Entity] as [Billing Entity]
 
 from 
 ( 
     select *
FROM IMIS.dbo.Assess_Notice 
unpivot
(
  Test
  for  NoticeType in (N1,N2,N3,N4,N5,N6,N7)
) as NoticeType  ) _
 LEFT JOIN BOOMI_DEV.dbo.VW_Billing_Entity b_ent  on b_ent.Id = _.ID and b_ent.ASSESS_YEAR = _.ASSESS_YEAR) base 
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.[Billing Entity] =  IMIS_name.ID
 LEFT JOIN BOOMI.dbo.vIMIS_Name  v_name on base.[Billing Entity] = v_name.[IMIS Account Number] 
 LEFT JOIN  IMIS.dbo.Loc_Info  loc_info  on loc_info.ID = base.[Billing Entity] 

 where v_name.[Billing Cycle] like 'jan%' and IMIS_name.STATUS != 'D'  and base.ASSESS_YEAR = '2019/20'
 ) main 
 LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  main.[Segment Code] = LTRIM(imis_seg_map.code_in_imis) 
 where rn = 1
Group by imis_seg_map.Category , NoticeType 
Order by imis_seg_map.Category , NoticeType

-------------==============================-----------
-- N NOtice for 2019/20 July Cycle
-------------==============================-----------
select  
imis_seg_map.Category as [Segment Category] , NoticeType , count(*) as [Count of Notices] 
 from  (
select 
loc_info.CURRENT_SEGMENT as [Segment Code] ,
base.[Notice Type] as NoticeType ,
ROW_NUMBER() over(partition by NoticeType , base.ASSESS_YEAR, base.[Billing Entity] order by base.ID)  as rn 
from 
( 
select 
_.*, 
case when _.NoticeType = 'N7' then 'N6' else _.NoticeType end as [Notice Type] ,
b_ent.[Billing Entity] as [Billing Entity]
 
 from 
 ( 
     select *
FROM IMIS.dbo.Assess_Notice 
unpivot
(
  Test
  for  NoticeType in (N1,N2,N3,N4,N5,N6,N7)
) as NoticeType  ) _
 LEFT JOIN BOOMI_DEV.dbo.VW_Billing_Entity b_ent  on b_ent.Id = _.ID and b_ent.ASSESS_YEAR = _.ASSESS_YEAR) base 
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.[Billing Entity] =  IMIS_name.ID
 LEFT JOIN BOOMI.dbo.vIMIS_Name  v_name on base.[Billing Entity] = v_name.[IMIS Account Number] 
 LEFT JOIN  IMIS.dbo.Loc_Info  loc_info  on loc_info.ID = base.[Billing Entity] 

 where v_name.[Billing Cycle] like 'jul%' and IMIS_name.STATUS != 'D'  and base.ASSESS_YEAR = '2019/20'
 ) main 
 LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  main.[Segment Code] = LTRIM(imis_seg_map.code_in_imis) 
 where rn = 1
Group by imis_seg_map.Category , NoticeType 
Order by imis_seg_map.Category , NoticeType

------------------------------------------------------
-- for child/ Account / Loc
------------------------------------------------------

-------------==============================-----------
-- N NOtice for 2018/19 January Cycle
-------------==============================-----------

select  
imis_seg_map.Category as [Segment Category] , NoticeType , count(*) as [Count of Notices] 
 from  (
select 
loc_info.CURRENT_SEGMENT as [Segment Code],   
case when base.NoticeType = 'N7' then 'N6' else base.NoticeType end as NoticeType 
 from 
 ( 
     select *
FROM IMIS.dbo.Assess_Notice 
unpivot
(
  Test
  for  NoticeType in (N1,N2,N3,N4,N5,N6,N7)
) as NoticeType  ) base
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.ID =  IMIS_name.ID
 LEFT JOIN BOOMI.dbo.vIMIS_Name  v_name on base.ID = v_name.[IMIS Account Number] 
 LEFT JOIN  IMIS.dbo.Loc_Info  loc_info  on loc_info.ID = base.ID 

 where v_name.[Billing Cycle] like 'jan%' and IMIS_name.STATUS != 'D'  and base.ASSESS_YEAR = '2018/19'
 ) main
 LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  main.[Segment Code] = LTRIM(imis_seg_map.code_in_imis)
Group by imis_seg_map.Category , NoticeType 
Order by imis_seg_map.Category , NoticeType


-------------==============================-----------
-- N NOtice for 2018/19 July Cycle
-------------==============================-----------

select  
imis_seg_map.Category as [Segment Category] , NoticeType , count(*) as [Count of Notices] 
 from  (
select 
loc_info.CURRENT_SEGMENT as [Segment Code],   
case when base.NoticeType = 'N7' then 'N6' else base.NoticeType end as NoticeType 
 from 
 ( 
     select *
FROM IMIS.dbo.Assess_Notice 
unpivot
(
  Test
  for  NoticeType in (N1,N2,N3,N4,N5,N6,N7)
) as NoticeType  ) base
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.ID =  IMIS_name.ID
 LEFT JOIN BOOMI.dbo.vIMIS_Name  v_name on base.ID = v_name.[IMIS Account Number] 
 LEFT JOIN  IMIS.dbo.Loc_Info  loc_info  on loc_info.ID = base.ID 

 where v_name.[Billing Cycle] like 'jul%' and IMIS_name.STATUS != 'D'  and base.ASSESS_YEAR = '2018/19'
 ) main
 LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  main.[Segment Code] = LTRIM(imis_seg_map.code_in_imis)
Group by imis_seg_map.Category , NoticeType 
Order by imis_seg_map.Category , NoticeType


-------------==============================-----------
-- N NOtice for 2019/20 January Cycle
-------------==============================-----------

select  
imis_seg_map.Category as [Segment Category] , NoticeType , count(*) as [Count of Notices] 
 from  (
select 
loc_info.CURRENT_SEGMENT as [Segment Code],   
case when base.NoticeType = 'N7' then 'N6' else base.NoticeType end as NoticeType 
 from 
 ( 
     select *
FROM IMIS.dbo.Assess_Notice 
unpivot
(
  Test
  for  NoticeType in (N1,N2,N3,N4,N5,N6,N7)
) as NoticeType  ) base
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.ID =  IMIS_name.ID
 LEFT JOIN BOOMI.dbo.vIMIS_Name  v_name on base.ID = v_name.[IMIS Account Number] 
 LEFT JOIN  IMIS.dbo.Loc_Info  loc_info  on loc_info.ID = base.ID 

 where v_name.[Billing Cycle] like 'jan%' and IMIS_name.STATUS != 'D'  and base.ASSESS_YEAR = '2019/20'
 ) main
 LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  main.[Segment Code] = LTRIM(imis_seg_map.code_in_imis)
Group by imis_seg_map.Category , NoticeType 
Order by imis_seg_map.Category 

-------------==============================-----------
-- N NOtice for 2019/20 July Cycle
-------------==============================-----------

select  
imis_seg_map.Category as [Segment Category] , NoticeType , count(*) as [Count of Notices] 
 from  (
select 
loc_info.CURRENT_SEGMENT as [Segment Code],   
case when base.NoticeType = 'N7' then 'N6' else base.NoticeType end as NoticeType 
 from 
 ( 
     select *
FROM IMIS.dbo.Assess_Notice 
unpivot
(
  Test
  for  NoticeType in (N1,N2,N3,N4,N5,N6,N7)
) as NoticeType  ) base
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.ID =  IMIS_name.ID
 LEFT JOIN BOOMI.dbo.vIMIS_Name  v_name on base.ID = v_name.[IMIS Account Number] 
 LEFT JOIN  IMIS.dbo.Loc_Info  loc_info  on loc_info.ID = base.ID 

 where v_name.[Billing Cycle] like 'jul%' and IMIS_name.STATUS != 'D'  and base.ASSESS_YEAR = '2019/20'
 ) main
 LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  main.[Segment Code] = LTRIM(imis_seg_map.code_in_imis)
Group by imis_seg_map.Category , NoticeType 
Order by imis_seg_map.Category 

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

select  
AuditYear , [Audit Status] , count(*) as [Audit counts]

from (select  [AuditYear],
		 case when LowTNT = 1 and LowTNT_Cleared is NUll  then 'open'  
		    when DecreaseRevenue = 1 and  DecreaseRevenue_Cleared is NUll  then 'open'
			when DecreaseTNT = 1 and  DecreaseTNT_Cleared  is Null then 'open' 
			when RepeatRevenue = 1 and RepeatRevenue_Cleared is Null then 'open' 
			when NoTNT = 1  and  NoTNT_Cleared = 0  then 'open'
			when NoSecondTNT = 1 and  NoSecondTNT_Cleared = 0  then 'open'
			when RoundedRevenue = 1 and RoundedRevenue_Cleared  = 0 then 'open'
			when LowTNT = 1 and LowTNT_Cleared is not NUll  then 'close'  
		    when DecreaseRevenue = 1 and  DecreaseRevenue_Cleared is not NUll  then 'close'
			when DecreaseTNT = 1 and  DecreaseTNT_Cleared  is not Null then 'close' 
			when RepeatRevenue = 1 and RepeatRevenue_Cleared is not Null then 'close' 
			when NoTNT = 1  and  NoTNT_Cleared = 1  then 'close'
			when NoSecondTNT = 1 and  NoSecondTNT_Cleared = 1  then 'close'
			when RoundedRevenue = 1 and RoundedRevenue_Cleared  = 1 then 'close'
			end as [Audit Status]
        ,  assess.ASSESS_YEAR 
		,  assess.Superseded
		,  assess.READY_TO_POST
        from IMIS.dbo.Assess_Audit  assess_audit 
        LEFT JOIN IMIS.dbo.Assess assess on assess.ID = assess_audit.ID and assess.ASSESS_YEAR = assess_audit.AuditYear
      ) base where [Audit Status] in ('open','close') and Superseded = 0 and READY_TO_POST = 1 
Group by [AuditYear], [Audit Status] order by [AuditYear]
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

select Type,[S cat], count(*) from 
( select  _.Category, Status,  [Segment Code], Type , imis_seg_map.Category as [S cat] from 
(select  Category, Status,  loc_info.[Segment Code] as [Segment Code], 
case when Status = 'A' and Category in ('LOC', 'RL')  and VCusField.[IMIS Account Number]  = VCusField.[Bill To Parent]  then 'Active Standalone LOCs' 
	 when Status = 'A' and Category in ('BIL', 'RB') and VCusField.[IMIS Account Number]  = VCusField.[Bill To Parent] then 'BILs' 
	 when Status in ('E','IP','IF','I','NA') and Category in ('LOC', 'RL')  and Has_Filed_Ever = 1  then 'Exempt'
	 else '' 
end as [Type] 
   from  [BOOMI].[dbo].[vIMIS_Name] base 
   LEFT JOIN   BOOMI_DEV.dbo.vIMIS_CalculatedFields  VCusField on base.[IMIS Account Number] = VCusField.[IMIS Account Number]
   LEFT JOIN  vIMIS_Loc_Info loc_info  on loc_info.[IMIS Account Number] = base.[IMIS Account Number] ) _
     LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  _.[Segment Code] = LTRIM(imis_seg_map.code_in_imis)) main
   where main.Type in ('Active Standalone LOCs','BILs' , 'Exempt') group by  Type,[S cat] Order by Type

-- for count of Active location 
select-- Type,[S cat]
--,[IMIS Account Number] 
 [S cat], count(*) 
from 
( select  [IMIS Account Number] ,_.Category, Status,  [Segment Code], Type , imis_seg_map.Category as [S cat]  from 
(select 
 base.[IMIS Account Number] , Category, Status,  loc_info.[Segment Code] as [Segment Code], 
case 
	when Status = 'A' and Category  in ('RL','LOC') and VCusField.[IMIS Account Number] != VCusField.[Bill To Parent]   then 'Bil Active Location'
	 else '' 
end as [Type] 
   from  [BOOMI].[dbo].[vIMIS_Name] base 
   LEFT JOIN   BOOMI_DEV.dbo.vIMIS_CalculatedFields  VCusField on base.[IMIS Account Number] = VCusField.[IMIS Account Number] 
   LEFT JOIN  vIMIS_Loc_Info loc_info  on loc_info.[IMIS Account Number] = base.[IMIS Account Number] ) _
     LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  _.[Segment Code] = LTRIM(imis_seg_map.code_in_imis)) main
 
     where Type in ('Bil Active Location') Group  by [S cat]


        --=================================--
-- What: All LOCs by region
-- Values: Counts
-- How: by region
-- Results: Counts must be the same in both system
select 
Region ,
count(*)
  from 
(select PURPOSE,
        ID,
		case when SUBSTRING(ZIP,0,CHARINDEX('-', ZIP)) != '' then SUBSTRING(ZIP,0,CHARINDEX('-', ZIP)) else ZIP end  as [ZIP_],
		ZIP from IMIS.dbo.Name_Address where ZIP != ''
		) name_addr
LEFT JOIN IMIS.dbo.Name IMIS_name on name_addr.ID =  IMIS_name.ID 
LEFT JOIN BOOMI_DEV.dbo.vIMIS_District VW_dist on VW_dist.ZIPCode = name_addr.ZIP_ 
where name_addr.ZIP !=  '' and name_addr.PURPOSE = 'Location' 
      and   IMIS_name.STATUS != 'D' 
      and MEMBER_TYPE != 'IND'
group by VW_dist.Region

        --=================================--
-- What: Previous year's revenue
-- Values : $$amounts
-- How: By segment by year
-- Results: Amounts must match in both systems
-- assessment calc


select
-- previous year revenue for assess 
 [Assess Year],
 [Segment Category],
 sum([IMIS Assessment Calculation]) as [Previous Year Revenue]
  from 
(
	select  * from (
 
	select assess.Assess_Year as [Assess Year],
	COALESCE(imis_seg_map.value_in_salesforce, acc.Segment_Code__C) as [Segment Code],
	COALESCE(imis_seg_map.category, acc.Segment_Category__C) as [Segment Category],
	case when assess.Exempt_Code not in  ('NOTOUR','UNDER1') then  assess.ASSESSMENT_CALC  end as [IMIS Assessment Calculation],
	IMIS_name.Status  as [Status] from IMIS.dbo.Assess assess
	LEFT JOIN IMIS.dbo.Name IMIS_name on assess.ID =  IMIS_name.ID
	LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  assess.segment = LTRIM(imis_seg_map.code_in_imis)
	LEFT JOIN BOOMI_DEV.dbo.PRODAccounts acc ON assess.ID = acc.TOURISM_ID__C  )
base where base.Status != 'D' and  base.[Assess Year] != '' and base.[Assess Year] = '2018/19' ) main 
where main.[Segment Category] is not Null and main.[Segment Category]!= 'Not Available' 
GROUP BY [Assess Year], [Segment Category]

UNION ALL


select 
 -- previous year revenue for assess_car
[Assess Year],
 [Segment Category],
 sum([IMIS Assessment Calculation]) as [Previous Year Revenue]
  from 
(
	select  base.[Assess Year],[Segment Category], base.[Status],[IMIS Assessment Calculation] 
	from (
	select 
     'Passenger Car Rental - E100' as [Segment Code],
	 'Passenger Car Rental' as [Segment Category],
	case
	  when MONTH(assess_car.PERIOD) > 0 and  MONTH(assess_car.PERIOD) <7 and YEAR(assess_car.PERIOD) - 1 < 2009 then TRY_CONVERT(varchar ,concat(YEAR(assess_car.PERIOD)-1,'/','0',YEAR(assess_car.PERIOD)%100))
      when MONTH(assess_car.PERIOD) > 0 and  MONTH(assess_car.PERIOD) <7 and YEAR(assess_car.PERIOD) - 1  >2008 then TRY_CONVERT(varchar ,concat(YEAR(assess_car.PERIOD)-1,'/',YEAR(assess_car.PERIOD)%100))
      when MONTH(assess_car.PERIOD) > 6 and  MONTH(assess_car.PERIOD) <13 and YEAR(assess_car.PERIOD) > 2008 then  TRY_CONVERT(varchar ,concat(YEAR(assess_car.PERIOD),'/',(YEAR(assess_car.PERIOD)+1)%100))
      when MONTH(assess_car.PERIOD) > 6 and  MONTH(assess_car.PERIOD) <13 and YEAR(assess_car.PERIOD) < 2009 then  TRY_CONVERT(varchar ,concat(YEAR(assess_car.PERIOD),'/','0',(YEAR(assess_car.PERIOD)+1)%100)) 
	 else  Null  end  as [Assess Year],
	
	assess_car.Total_Assessment [IMIS Assessment Calculation],
	IMIS_name.Status  as [Status] 
  from IMIS.dbo.Assess_Car assess_car
	LEFT JOIN IMIS.dbo.Name IMIS_name on assess_car.ID =  IMIS_name.ID  )
base where base.Status != 'D' and  base.[Assess Year] != '' and base.[Assess Year] = '2018/19' ) main 
where main.[Segment Category] is not Null and main.[Segment Category]!= 'Not Available'
 GROUP BY [Assess Year], [Segment Category]