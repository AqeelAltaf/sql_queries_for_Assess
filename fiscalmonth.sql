-- query to get count of parents with Fiscal Month
select assess.ID ,acc.CATEGORY_TYPE__C,acc.BILL_TO_PARENT__C , acc.ID,
case when acc.CATEGORY_TYPE__C  = 'Exempt' and acc.BILL_TO_PARENT__C is Null then 'standalone Bill'
     when acc.CATEGORY_TYPE__C  = 'Parent' and acc.BILL_TO_PARENT__C is Null then dbo.getFiscalMonthfromAssessCount(acc.ID)
 end as [a] 
from IMIS.dbo.Assess assess 
LEFT JOIN BOOMI_DEV.dbo.PRODAccounts acc ON assess.ID = acc.TOURISM_ID__C
where acc.CATEGORY_TYPE__C  = 'Parent' 
-- or (acc.BILL_TO_PARENT__C is Null and acc.CATEGORY_TYPE__C  = 'Exempt') 
and assess.ASSESS_YEAR in ('2017/18','2018/19','2019/20')
-- or (acc.BILL_TO_PARENT__C = '' and acc.CATEGORY_TYPE__C  = 'Exempt')


-- function to get count of distinct Fiscal Months for the bill by  from their children
ALTER FUNCTION dbo.getFiscalMonthfromAssessCount(@Parent varchar(255))  
RETURNS VARCHAR(255) as
BEGIN
RETURN (
select
count(distinct case when FISCAL_MONTH != '' then FORMAT(CONVERT(INT,[FISCAL_MONTH]), '00')  else '' end )
 from IMIS.dbo.Assess assess 
RIGHT JOIN BOOMI_DEV.dbo.PRODAccounts acc ON assess.ID = acc.TOURISM_ID__C
where  acc.BILL_TO_PARENT__C = @Parent and acc.CATEGORY_TYPE__C != 'Exempt' and assess.ASSESS_YEAR in ('2017/18','2018/19','2019/20') and assess.FISCAL_MONTH != '' --GROUP BY assess.FISCAL_MONTH ORDER BY [fiscalMonthCount]
)  
End
go



-- function to get Fiscal Month for the bill by the most count of fiscal month from their children
ALTER FUNCTION dbo.getFiscalMonthfromAssess(@Parent varchar(255))  

RETURNS VARCHAR(255) as
BEGIN
RETURN (
select top 1 case when count(*) over(partition by [fiscalMonthCount] order by [fiscalMonthCount] DESC) > 1 then 'tie' else [Fiscal End Month] end as a from
(
select top 10
 [Fiscal End Month],count(*)  as [fiscalMonthCount] from 
(
    select
	  case when FISCAL_MONTH != '' then FORMAT(CONVERT(INT,[FISCAL_MONTH]), '00')  else '' end   as [Fiscal End Month]
   
    from IMIS.dbo.Assess assess 
RIGHT JOIN BOOMI_DEV.dbo.PRODAccounts acc ON assess.ID = acc.TOURISM_ID__C
where  acc.BILL_TO_PARENT__C = @Parent and assess.ASSESS_YEAR in ('2017/18','2018/19','2019/20') and assess.FISCAL_MONTH != '') base
GROUP BY base.[Fiscal End Month] ) _ ORDER BY [fiscalMonthCount] DESC 
)  
End
go


-- query to get status of  all assess 
select  a , count(a) from (select distinct assess.ID ,acc.CATEGORY_TYPE__C,acc.BILL_TO_PARENT__C , --acc.ID,

case when acc.CATEGORY_TYPE__C  = 'Exempt' and acc.BILL_TO_PARENT__C is Null then 'standalone Bill'
     when acc.CATEGORY_TYPE__C  = 'Parent' 
	 and 
	 (select count(*) from PRODAccounts where BILL_TO_PARENT__C = assess.ID ) 
	 = (select count(*) from PRODAccounts where BILL_TO_PARENT__C = assess.ID and CATEGORY_TYPE__C = 'Exempt' )  then 'exempted bill'
	 else 'check for child fiscals' end as [a] 
from IMIS.dbo.Assess assess 
LEFT JOIN BOOMI_DEV.dbo.PRODAccounts acc ON assess.ID = acc.TOURISM_ID__C
where acc.CATEGORY_TYPE__C  = 'Parent' 
or (acc.BILL_TO_PARENT__C is Null and acc.CATEGORY_TYPE__C  = 'Exempt') 
and assess.ASSESS_YEAR in ('2017/18','2018/19','2019/20')) _ group by a 

