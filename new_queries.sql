select * from BOOMI_DEV.dbo.VW_IMIS_Assess where [Segment Category] is Null or [Segment Category] = ''

select  DISTINCT [Assess Year], [Segment Category], count(*) from BOOMI_DEV.dbo.VW_IMIS_Assess where [Primary Assessment Rate] is Null group by [Assess Year], [Segment Category]
select * from BOOMI_DEV.dbo.IMIS_to_sf_seg_map


select count(*) from IMIS.dbo.Assess 

left join BOOMI_DEV.dbo.PRODAccounts acc on assess.ID = acc.TOURISM_ID__C where   assess.SEGMENT   = '' and acc.SEGMENT_CATEGORY__C is Null


-- To explore empty rates 
select Account,[Segment Category], [Segment Code] from BOOMI_DEV.dbo.VW_IMIS_Assess where  [Primary Assessment Rate] is Null
select SEGMENT from IMIS.dbo.Assess where ASSESS_YEAR = '2017/18' and ID = '1763406'
select SEGMENT_CATEGORY__C, SEGMENT_CODE__C from BOOMI_DEV.dbo.PRODAccounts where Tourism_ID__C ='1763406'
select SEGMENT from IMIS.dbo.Assess where ASSESS_YEAR = '2017/18' and ID = '1830442'
select SEGMENT_CATEGORY__C, SEGMENT_CODE__C from BOOMI_DEV.dbo.PRODAccounts where Tourism_ID__C ='183044'



-- checking duplicate for Assess Audit View
Select Account, [Audit Year], count(*) from BOOMI_DEV.dbo.VW_IMIS_Assess_Audit assess_audit_vw group By assess_audit_vw.Account ,assess_audit_vw.[Audit Year] having count(*) > 1
-- checking duplicate for Segment Max
Select [PreviousFiscalYear], [SEGMENT_CODE__C],count(*) from  BOOMI_DEV.dbo.SegmentMax seg_max group By seg_max.[PreviousFiscalYear], seg_max.[SEGMENT_CODE__C] having count(*) > 1
-- query for details of duplicates in Segment Max
select * from BOOMI_DEV.dbo.SegmentMax seg_max where  seg_max.[PreviousFiscalYear] = '2013/14' and SEGMENT_CODE__C = 'Hotels - A125'
--to tally count of rows in Assess
select   count(*) from dbo.VW_IMIS_Assess

select  count(*) from ( 
select assess.ASSESS_YEAR ,assess.ID,IMIS_name.ID as[ID_],IMIS_name.Status  from IMIS.dbo.Assess assess
LEFT JOIN IMIS.dbo.Name IMIS_name on assess.ID =  IMIS_name.ID )   base where base.Status != 'D' and  base.Assess_Year != ''

select   count(*) from dbo.VW_IMIS_rev_Assess

select count(distinct [External ID]) from dbo.VW_IMIS_rev_Assess where [Assess Year] != '2012/13' and [Segment Code] != 'Hotels - A125'
select * from dbo.VW_IMIS_rev_Assess [Assess Year] != '2012/13' and [Segment Code] != 'Hotels - A125'
-- getting those record which are duplicate in Assess_Audit
select * from IMIS.dbo.Assess_Audit ass_aud RIGHT JOIN
(select Id , AuditYear from IMIS.dbo.Assess_Audit group by Id , AuditYear having count(*) > 1 ) base on  ass_aud.Id = base.Id and ass_aud.AuditYear = base.AuditYear

select count(DISTINCT SEQN) from IMIS.dbo.Assess_Audit ass_aud RIGHT JOIN
(select Id , AuditYear from IMIS.dbo.Assess_Audit group by Id , AuditYear having count(*) > 1 ) base   on  ass_aud.Id = base.Id and ass_aud.AuditYear = base.AuditYear







--========== to tally count of rows in Assess =============--
-- all records in Asess IMIS table 
select   count(*) from dbo.VW_IMIS_Assess
-- all records in Asess IMIS table which status in not 'D' 
select  count(*) from ( 
select assess.ASSESS_YEAR ,assess.ID,IMIS_name.ID as[ID_],IMIS_name.Status  from IMIS.dbo.Assess assess
LEFT JOIN IMIS.dbo.Name IMIS_name on assess.ID =  IMIS_name.ID )   base where base.Status != 'D' and  base.Assess_Year != ''

select   count(*) from dbo.VW_IMIS_rev_Assess

--to tally count of rows in intermediate Assess View
select   count(*) from dbo.VW_IMIS_Assess

select  count(*) from ( 
select assess.ASSESS_YEAR ,assess.ID,IMIS_name.ID as[ID_],IMIS_name.Status  from IMIS.dbo.Assess assess
LEFT JOIN IMIS.dbo.Name IMIS_name on assess.ID =  IMIS_name.ID )   base where base.Status != 'D' and  base.Assess_Year != ''



            --=================================--

--========== to tally count of rows in Assess Car =============--

-- total records in Assess Car IMIS
select count(*) from IMIS.dbo.Assess_Car
-- all records in Asess Car IMIS table which status in not 'D' ogic
select  count(*) from ( 
select assess_car.ID,IMIS_name.ID as[ID_],IMIS_name.Status  from IMIS.dbo.Assess_Car assess_car
LEFT JOIN IMIS.dbo.Name IMIS_name on assess_car.ID =  IMIS_name.ID )   base where base.Status != 'D'
--counts in final view 
select count(*) from dbo.VW_IMIS_rev_Assess_Car


-- making Billing Entity Table
select Id, ASSESS_YEAR, 
IMIS_Service.dbo.fn_TransParentID(Id, ASSESS_YEAR)  as [Billing Entity] 
INTO BOOMI_DEV.dbo.VW_Billing_Entity   
from IMIS.dbo.Assess_Notice

-- this function returns the most frequent Letter date for the given  Asses Year , Notice Type and Billing Entity
-- this function returns the most frequent Letter date for the given  Asses Year , Notice Type and Billing Entity
ALTER FUNCTION dbo.getLetterDate(@AssessYear varchar(255), @NoticeType varchar(255), @BillingEntity varchar(255))  

-- this function returns the most frequent Letter date for the given  Asses Year , Notice Type and Billing Entity
RETURNS VARCHAR(255) AS
BEGIN
    RETURN 
	(
		--SELECT TOP 1 B1 FROM  IMIS.dbo.Assess_Notice WHERE B1 IS NOT NULL 
		select Top 1 
			case when @AssessYear =    '2015/16' and count([Count of Letter]) over( partition By [Count of Letter] ) > 1 then CONCAT('01/0',right(@NoticeType, 1),'/1900')
			      when @AssessYear =   '2016/17' and count([Count of Letter]) over( partition By [Count of Letter] ) > 1 then CONCAT('01/0',right(@NoticeType, 1),'/1901')
		 	     else  Convert(varchar(30),[Letter Date],102)  end
		  from 
		(select Top 1
		  [Letter Date] , 
		  COUNT( [Letter Date] ) as [Count of Letter]
		from 
			(select Id, ASSESS_YEAR, NoticeType, FORMAT(Test  , 'MM/dd/yyyy') as [Letter Date]
			FROM IMIS.dbo.Assess_Notice 
			unpivot
			(
			  Test
			  for  NoticeType in (AQ1,AQ2,AQ3,N1,N2,N3,N4,N5,N6,N7,B1,B2,B3,B4,B5,A1,A2,A3)
			) as NoticeType ) base  LEFT JOIN BOOMI_DEV.dbo.VW_Billing_Entity b_ent  
			on b_ent.Id = base.ID and b_ent.ASSESS_YEAR = base.ASSESS_YEAR 
			where base.ASSESS_YEAR = @AssessYear  and base.NoticeType = @NoticeType and b_ent.[Billing Entity] = @BillingEntity
			Group By  [Letter Date]  ORDER BY COUNT( [Letter Date] ) DESC) main
	)
END
GO

select dbo.getLetterDate('2016/17','N1','1350011')
select dbo.getLetterDate('2015/16','N2','1191516')
select dbo.getLetterDate('2016/17','N2','1380356')


-- query to get records which have more than one letter date 
SELECT [Billing Entity], [Assess Year],[Notice Type],  [Letter Date] , COUNT(*) FROM (
   select
    base.Test as [Letter Date],
	[Billing Entity],
    case when base.[NoticeType] = 'N7' then 'N6' else base.[NoticeType] end as [Notice Type],
    base.SEQN   as [Current SEQN],
    base.Id as [Account],
    base.ASSESS_YEAR as [Assess Year],
    IMIS_name.STATUS as [Status Flag],
	COUNT(*) OVER(partition BY    [Billing Entity], base.ASSESS_YEAR  ,base.[NoticeType]  ) as [group count] 

 from 
 ( 
     select *,IMIS_Service.dbo.fn_TransParentID(Id, ASSESS_YEAR)  as [Billing Entity]
        FROM IMIS.dbo.Assess_Notice 
        unpivot
        (
        Test
        for  NoticeType in (AQ1,AQ2,AQ3,N1,N2,N3,N4,N5,N6,N7,B1,B2,B3,B4,B5,A1,A2,A3)
) as NoticeType  ) base
 LEFT JOIN IMIS.dbo.Name IMIS_name on base.Id =  IMIS_name.ID  where IMIS_name.STATUS !='D' and  base.ASSESS_YEAR in ('2015/16', '2016/17') ) main WHERE  [group count] > 1
 GROUP BY [Billing Entity], [Assess Year],[Notice Type],  [Letter Date]  
 ORDER BY  [Billing Entity], [Assess Year],[Notice Type],  [Letter Date]  


-- Provide the list of accounts where Bill To and Child has different bill cycles.
-- Provide the list of accounts where Bill To and Child has different bill cycles.
select TOURISM_ID__C,BILLING_CYCLE__C   from  
   (select
       CATEGORY_TYPE__C 
	 , BILLING_CYCLE__C
     , ID 
	 , TOURISM_ID__C
     , (select count(distinct BILLING_CYCLE__C ) from BOOMI_DEV.dbo.PRODAccounts where BILL_TO_PARENT__C = base.ID and CATEGORY_TYPE__C  ='Assessed') as [child bcycle count] 
from (select * from BOOMI_DEV.dbo.PRODAccounts where CATEGORY_TYPE__C = 'Parent') base ) _ 
where [child bcycle count]  > 1


-- Exempt Status view for account
ALTER VIEW dbo.VW_IMIS_AccountExemptStatus
as 
-- this view contains all the latest assess records which have Exempt Status  =  'Exempt – Business Size (Revenue) 1 year'
select  * ,'Exempt – Business Size (Revenue) 1 year' as [Exempt Status] 
from  
(
select assess.ID  
, assess.Assess_Year 
,IMIS_name.Status 
,EXEMPT_CODE 
,ROW_NUMBER() over(PARTITION BY assess.ID  ORDER BY assess.Assess_Year DESC) as rn
, Superseded
from IMIS.dbo.Assess  assess 
LEFT JOIN IMIS.dbo.Name IMIS_name on assess.ID =  IMIS_name.ID ) _ 
where rn = 1 and EXEMPT_CODE in ('MVDOUT','NOTOUR','UNDER1','UNDER8','UNDR1','UNDR20','UNDR50') and  Superseded = 0 and Status  != 'D'



-- View for Assess Percentage Torism which have Complete = 0, Exempt_Code != '' and Primary Percent Tourism = 0
Create VIEW dbo.Assess_Perc_Tourism as
select CONCAT(SEQN,'-',ID) as [External ID] 
       , [Primary Percent Tourism]
	   , [Percent Tourism] 
	  from 
(select --acc_tour.[Tourism ID] as ID
      --,
	    assess.ID
	  , assess.SEQN
      , case when SUBSTRING(assess.ASSESS_YEAR,0,CHARINDEX('/', assess.ASSESS_YEAR)) < '2006'then assess.PERCENT_TOURISM 
	              else assess.S_PERCENT_TOURISM end as [Primary Percent Tourism]
      , acc_tour.[Percent Tourism] 
 from dbo.accounts_with_tourism  acc_tour
INNER JOIN IMIS.dbo.Assess assess on acc_tour.[Tourism ID] = assess.ID
where assess.COMPLETE =  0 
and assess.EXEMPT_CODE =  '') base where [Primary Percent Tourism] =  0 




-- function to get count of distinct Fiscal Months for the bill by  from their children
ALTER FUNCTION dbo.get2017FiscalMonthfromAssessfor(@ID varchar(255))  
RETURNS VARCHAR(255) as
BEGIN
RETURN (
select
count(distinct case when FISCAL_MONTH != '' then FORMAT(CONVERT(INT,[FISCAL_MONTH]), '00')  else '' end )
 from IMIS.dbo.Assess assess 
RIGHT JOIN BOOMI_DEV.dbo.PRODAccounts acc ON assess.ID = acc.TOURISM_ID__C
where  acc.BILL_TO_PARENT__C = @Parent and acc.CATEGORY_TYPE__C != 'Exempt' and assess.ASSESS_YEAR in ('2017/18','2018/19','2019/20') and assess.FISCAL_MONTH != '' 
)  
End
go