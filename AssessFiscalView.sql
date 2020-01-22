ALTER VIEW [dbo].[VW_IMIS_Asess_Fiscals]
AS
select SEQN
,ID
, ASSESS_YEAR 
/*,SUBSTRING(ASSESS_YEAR,0,CHARINDEX('/', ASSESS_YEAR)) as [assess_part]
, SUBSTRING([Fn Assess Year],0,CHARINDEX('/', [Fn Assess Year])) as [fn_assess_part],
 convert(int,SUBSTRING([Fn Assess Year],0,CHARINDEX('/', [Fn Assess Year]))) - convert(int,SUBSTRING(ASSESS_YEAR,0,CHARINDEX('/', ASSESS_YEAR))) as dif,*/
 ,[Fn Fiscal Month] as [Fiscal Month]
 ,convert(float,[Fn Fiscal Year]) - (convert(int,SUBSTRING([Fn Assess Year],0,CHARINDEX('/', [Fn Assess Year]))) - convert(int,SUBSTRING(ASSESS_YEAR,0,CHARINDEX('/', ASSESS_YEAR)))) as [Fiscal Year]
 from 
(   
    SELECT SEQN
	     , ID
	     , ASSESS_YEAR 
	     , FISCAL_YEAR as [old Fiscal Year] ,

    case when FISCAL_YEAR = '' and ASSESS_YEAR >= '2017/18' and assess.READY_TO_POST = 0 then 'our row' end as [flag],
    FIRST_VALUE( assess.ASSESS_YEAR ) OVER ( 
            PARTITION BY ID
            ORDER BY 
                case when ASSESS_YEAR < '2016/17' or Superseded = 1 or FISCAL_YEAR = '' then  '1900/01' ELSE ASSESS_YEAR end DESC
	      ) as [Fn Assess Year]
 
    ,FIRST_VALUE( assess.FISCAL_YEAR ) OVER ( 
        PARTITION BY ID
        ORDER BY 
                case when ASSESS_YEAR < '2016/17' or Superseded = 1 or FISCAL_YEAR = '' then '1900/01' ELSE ASSESS_YEAR end DESC 
	      ) as [Fn Fiscal Year]
	 
     , FIRST_VALUE( assess.FISCAL_MONTH ) OVER ( 
        PARTITION BY ID
        ORDER BY 
                case when ASSESS_YEAR < '2016/17' or Superseded = 1 or FISCAL_MONTH = '' then '1900/01' ELSE ASSESS_YEAR end DESC 
	      ) as [Fn Fiscal Month new]
       ,
       case when assess.Fiscal_Month != '' then RIGHT('0'+assess.Fiscal_Month,2)  
            when assess.FISCAL_MONTH = '' and assess.ASSESS_YEAR >= '2017/18' and assess.READY_TO_POST = 0   then 
            FIRST_VALUE( assess.FISCAL_MONTH ) OVER ( 
            PARTITION BY assess.Id
            ORDER BY assess.ASSESS_YEAR DESC,
            case when assess.ASSESS_YEAR < '2016/17' or Superseded = 1 then '' ELSE FISCAL_MONTH end ASC
	    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) 
        else ''  end as [Fn Fiscal Month]

from IMIS.dbo.Assess  ) base   where [flag] = 'our row' and [Fn Assess Year] >= '2017/18' and ([Fn Fiscal Year] != '' or [Fn Fiscal Month]!= '')


select  ID, ASSESS_YEAR  , count(* ) from dbo.VW_IMIS_Asess_Fiscals  GRoup By ID, ASSESS_YEAR  having count(*) > 1


select * from dbo.VW_IMIS_Asess_Fiscals