ALTER VIEW dbo.VW_IMIS_Assess_Car
AS
 (
   
select
[Account],
[Assess Year],
[Authorized Person Email],
[Authorized Person First Name],
[Authorized Person Last Name],
COALESCE(IMIS_Service.dbo.fn_TransParentID(Account, [Assess Year]), [Account]) as [Billing Entity],
[Completed Date],
[Filed By User],
assess_notice.N_FILEDATE as [Filed Date],
[Filed Online],
[Fiscal End Date],
[Fiscal End Month],
[Fiscal Start Date],
[Fiscal Start Month],
[IMIS Assessment Calculation],
[Period],
--Get data from segment rate table and keep it in IMIS, then give assess year and segment to this table and ge rate from there for all years except 2006/07.
--For year 2006/07 you will get data from assess table, get max no from assessment_rate or s_assessment_rate.  
rates.RATE__C  as [Primary Assessment Rate],
[Primary Gross Revenue],
[Segment Code],
[Segment Category],
[Signature],
concat([External Id],'-',[Account]) as [External Id]

 from 
     (
select
IMIS_name.STATUS as [Status Flag],
assess_car.ID  as [Account],


--"for eg: if period = ""2016-07-01 00:00:00.000"" or ""2016-08-01 00:00:00.000""then assess year will be 2016/17.
--If period = ""2017-01-01 00:00:00.000"" or ""2017-03-01 00:00:00.000"" then assess year will be 2016/17."
case when MONTH(assess_car.PERIOD) > 0 and  MONTH(assess_car.PERIOD) <7 and YEAR(assess_car.PERIOD) - 1 < 2009 then TRY_CONVERT(varchar ,concat(YEAR(assess_car.PERIOD)-1,'/','0',YEAR(assess_car.PERIOD)%100))
     when MONTH(assess_car.PERIOD) > 0 and  MONTH(assess_car.PERIOD) <7 and YEAR(assess_car.PERIOD) - 1  >2008 then TRY_CONVERT(varchar ,concat(YEAR(assess_car.PERIOD)-1,'/',YEAR(assess_car.PERIOD)%100))
     when MONTH(assess_car.PERIOD) > 6 and  MONTH(assess_car.PERIOD) <13 and YEAR(assess_car.PERIOD) > 2008 then  TRY_CONVERT(varchar ,concat(YEAR(assess_car.PERIOD),'/',(YEAR(assess_car.PERIOD)+1)%100))
     when MONTH(assess_car.PERIOD) > 6 and  MONTH(assess_car.PERIOD) <13 and YEAR(assess_car.PERIOD) < 2009 then  TRY_CONVERT(varchar ,concat(YEAR(assess_car.PERIOD),'/','0',(YEAR(assess_car.PERIOD)+1)%100)) 
	 else  Null  end  as [Assess Year],
assess_car.Contact_Email as [Authorized Person Email],

-- Bill to parent of current account if bill to parent is blank then populate it self id
--case when BILL_TO_PARENT__C is not Null then acc.IMIS_ID else acc.TOURISM_ID__C end as [Billing Entity],
--split AUTHORIZED_REP with space first name will come in this
SUBSTRING(assess_car.AUTHORIZED_REP,0,CHARINDEX(' ', assess_car.AUTHORIZED_REP)) AS [Authorized Person First Name],
-- split AUTHORIZED_REP with space last name will come in this
SUBSTRING(assess_car.AUTHORIZED_REP,CHARINDEX(' ', assess_car.AUTHORIZED_REP) + 1,LEN(assess_car.AUTHORIZED_REP)) AS [Authorized Person Last Name],
FORMAT(assess_car.DATE_RECEIVED , 'MM/dd/yyyy')as [Completed Date],
-- If Contact_Email is found in SF then populate that contact in this  lookup otherwise leave it blank.
email.CONTACT__R#IMIS_CONTACT_NUMBER__C as [Filed By User],

assess_car.Filed_online as [Filed Online],
assess_car.Total_Assessment as [IMIS Assessment Calculation],
--For eg: if period = "2016-10-01 00:00:00.000" then fiscal end date will be "2016-10-31 00:00:00.000".
Format(EOMonth(assess_car.PERIOD) , 'MM/dd/yyyy')  as [Fiscal End Date],
case when Month(assess_car.PERIOD) != '' then FORMAT(Month(assess_car.PERIOD),'00') else null  end as [Fiscal End Month],
--Make sure format of date will be MM/DD/YYYY 
Format(assess_car.PERIOD, 'MM/dd/yyyy') as [Fiscal Start Date],
--get the month part from column PERIOD and put here
case when Month(assess_car.PERIOD) != '' then FORMAT(Month(assess_car.PERIOD),'00') else null  end as [Fiscal Start Month],
case when Month(assess_car.PERIOD) != '' then FORMAT(Month(assess_car.PERIOD),'00') else null  end as [Period],
'Passenger Car Rental - E100' as [Segment Code],
'Passenger Car Rental'  as [Segment Category],
assess_car.QUANTITY as [Primary Gross Revenue],
assess_car.SIGNATURE as [Signature] ,
assess_car.IsPaid as [IMIS IsPaid],
assess_car.seqn as [External Id]
from  IMIS.dbo.Assess_car assess_car 
LEFT JOIN BOOMI_DEV.dbo.Email__c email ON assess_car.Contact_Email = email.NAME
lEFT JOIN (select acc1.*, acc2.IMIS_ID__C as [IMIS_ID]  from BOOMI_DEV.dbo.PRODAccounts acc1 left join BOOMI_DEV.dbo.PRODAccounts  acc2 on acc1.BILL_TO_PARENT__C = acc2.ID) acc ON assess_car.ID = acc.TOURISM_ID__C

LEFT JOIN IMIS.dbo.Name IMIS_name on assess_car.ID =  IMIS_name.ID) base 
LEFT JOIN IMIS.dbo.Assess_Notice assess_notice on base.Account = assess_notice.ID and base.[ASSESS YEAR] = assess_notice.ASSESS_YEAR
--LEFT JOIN IMIS.dbo.Assess_Audit assess_audit on base.Account = assess_audit.ID and base.[ASSESS YEAR] = assess_audit.AuditYear
LEFT JOIN BOOMI_DEV.dbo.SegmentRate rates on base.[Assess Year] = rates.[AssessYear] and LTRIM(base.[Segment Category]) = rates.[SegmentCategory]
where base.[Status Flag] != 'D'
)
GO