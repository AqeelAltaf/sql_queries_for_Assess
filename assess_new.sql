ALTER VIEW dbo.VW_IMIS_Assess
AS
 ( 
   select

[Account],
 --  Amended From != '' then true else false
 case when base.[Amended From] is not null then 'True' else 'False' end as [Amended],
 case when base.[Superseded] = 1 then 'True' else 'False' end as [Inactive],
[Amended From],
[Assess Mail],
[Assess Year],
[Authorized Person Email],
[Authorized Person First Name],
[Authorized Person Last Name],
[Bill Cycle],
COALESCE(IMIS_Service.dbo.fn_TransParentID(Account, [Assess Year]), [Account]) as [Billing Entity],
[Completed],
[Completed By Contact],
[Completed Date],
[Customer Calculation],
[Exempt Status],
[Exempt Notes],
[Filed By User],
[Filed Online],
[Filed Date],
[Fiscal End Date],
FORMAT(CONVERT(INT,[Fiscal End Month]), '00') [Fiscal End Month],
[Fiscal Start Date],
[Fiscal Start Month],
[Gross Reciept],
[IMIS Assessment Calculation],
[IMIS Interest],
[IMIS IsPaid],
[IMIS Num of Months],
[Pass Thru Total],
[IMIS Post Mark Date],
   --Get data from segment rate table and keep it in IMIS, then give assess year and segment to this table and ge rate from there for all years except  
 rates.RATE__C  as [Primary Assessment Rate], 
[Primary Gross Revenue],
[Primary Percent Tourism],
[Payment Overage],
[IMIS Payment Plan],
[IMIS Ready to Post],
[Secondary Assessment Rate],
[Secondary Gross Revenue],
[Secondary Percent Tourism],
[Segment Category],
[Segment Code],
-- = If segment max is blank then query data from segment max table for last assess year and current notice segment.
case when [Segment Max] > 0 then  [Segment Max] else  seg_max.RATE__C end as [Segment Max],
[Signature],
[Supersede By],
[Superseded],
[Total Admin Fees],
[Use Seg Max],
[IMIS Under 1M Comment],
[Voluntary Assessment],
[IMIS Voluntary Max],
concat([External Id],'-',[Account]) as [External Id]
 from
 (select
 IMIS_name.STATUS as [Status Flag],
 -- Use external id to populate this field
  assess.ID as 'Account',
  --case when Superseded = 0 and assess1.sup_flag = 2 then first_value(SEQN) OVER(partition by  assess.id, assess.Assess_year ORDER by  Superseded desc) else Null end as [Amended From],
   LAG(assess.SEQN) over(partition by assess.ID, assess.Assess_Year order by assess.SEQN, assess.Superseded DESC ) as [Amended From],
  -- Make sure format of date will be MM/DD/YYYY 
  FORMAT (assess.ASSESS_MAIL, 'MM/dd/yyyy') as [Assess Mail],
  assess.Assess_Year as [Assess Year],
  assess.Contact_Email as 'Authorized Person Email',
  -- split AUTHORIZED_REP with space first name will come in this
  SUBSTRING(assess.AUTHORIZED_REP,0,CHARINDEX(' ', assess.AUTHORIZED_REP)) AS [Authorized Person First Name],
  -- split AUTHORIZED_REP with space first name will come in this
  SUBSTRING(assess.AUTHORIZED_REP,CHARINDEX(' ', assess.AUTHORIZED_REP) + 1,LEN(assess.AUTHORIZED_REP)) AS [Authorized Person Last Name],
  case when LOWER(assess.BILL_CYCLE) like 'jan%' then 'January' when  LOWER(assess.BILL_CYCLE) like 'jul%' then 'July' else BILL_CYCLE end as [Bill Cycle],
  --Bring all accounts data in sql table, then search Assess.ID in tourism id field of account if account record is found then get data from bill_to_parent parent field and popultae here, if Bill_to_parent field is empty then populate acount tourism id
  --case when BILL_TO_PARENT__C is not Null then acc.IMIS_ID else acc.TOURISM_ID__C end as [Billing Entity],
  --COALESCE(acc.BILL_TO_PARENT__C,(str(acc.TOURISM_ID__C))) as [Billing Entity],
  
  assess.[READY_TO_POST] as [Completed],
  -- this is old logic 
  -- If completed date is not blank mark this true
  -- case when assess.DATE_RECEIVED is not null then 'True' else 'False'  end as [Completed] ,
  -- Bring all contacts and email object data in sql tables then search contact email in email table if email found then get the contact record of this email and populate in this field
  email.CONTACT__R#IMIS_CONTACT_NUMBER__C as [Completed By Contact],
  FORMAT (assess.DATE_RECEIVED , 'MM/dd/yyyy') as [Completed Date],
  assess.ASSESSMENT_LOC as [Customer Calculation],
  --All the exempt codes will be mapped to "Exempt – Other" picklist value except UNDER1  and NOTOUR, in case of these set IMIS assessment cal to 0 and keep these codes as is in this picklist
  case when assess.Exempt_Code not in  ('','NOTOUR','UNDER1') then  'Exempt – Other'  when assess.Exempt_Code in  ('NOTOUR','UNDER1') then assess.Exempt_Code  else '' end as [Exempt Status],
  assess.Exempt_Note as [Exempt Notes],
  --Bring all contacts and email object data in sql tables then search contact email in email table if email found then get the contact record of this email and populate in this field
  email.CONTACT__R#IMIS_CONTACT_NUMBER__C as [Filed By User],
  Format(assess_notice.N_FILEDATE,'MM/dd/yyyy') as [Filed Date],
  assess.Filed_online as 'Filed Online',
  --This means if 12 is start month then 12-1 will be nov
  case when assess.FISCAL_MONTH > 0 and  assess.FISCAL_MONTH < 12  then  FORMAT(CONVERT(INT,assess.Fiscal_Month +1), '00')  when assess.FISCAL_MONTH = 12 then '01' else null end as [Fiscal Start Month],
    --If Under_1M_End date is empty then create date with below logic day =1,Month=fiscal end month,Year=fiscal_year
--else Uner_1M_End date. Make sure format of date will be MM/DD/YYYY


	  case when COALESCE(
    assess.Under1M_EndDate,
  TRY_CONVERT(date,CONCAT(assess.FISCAL_YEAR,'/',assess.FISCAL_MONTH,'/','1'))) is not null then FORMAT(EOMONTH(TRY_CONVERT(date,CONCAT(assess.FISCAL_YEAR,'/',assess.FISCAL_MONTH,'/','1'))),'MM/dd/yyyy') else Null end
   as [Fiscal End Date],
  --If Under_1M_Begin date is empty then create date with below logic day =1,Month=fiscal start month,Year=fiscal_year
 --else Uner_1M_Begin date. Make sure format of date will be MM/DD/YYYY "
	  case when COALESCE(
    assess.Under1M_BeginDate,
  TRY_CONVERT(date,CONCAT(assess.FISCAL_MONTH,'/','1','/',assess.FISCAL_YEAR))) is not null then FORMAT(DATEADD(Month,-11,TRY_CONVERT(date,CONCAT(assess.FISCAL_MONTH,'/','1','/',assess.FISCAL_YEAR))),'MM/dd/yyyy') else Null end
   as [Fiscal Start Date],
  case when assess.Fiscal_Month != '' then RIGHT('0'+assess.Fiscal_Month,2) else null  end as 'Fiscal End Month',
  assess.GROSS_RECEIPTS as 'Gross Reciept',
  case when assess.Exempt_Code not in  ('','NOTOUR','UNDER1') then  assess.ASSESSMENT_CALC  else  0  end as [IMIS Assessment Calculation],
  assess.Interest as 'IMIS Interest',
  assess.isPaid as 'IMIS IsPaid',
  assess.NUM_OF_MONTHS as [IMIS Num of Months],
  assess.PASS_THRU_TOTAL as [Pass Thru Total],
  -- Make sure format of date will be MM/DD/YYYY 
  FORMAT (assess.POSTMARK_DATE, 'MM/dd/yyyy') as [IMIS Post Mark Date],
  -- Primary Revenue=Gross Recipt+S_Gross_Rev
  assess.GROSS_RECEIPTS + assess.S_GROSS_REVENUE as [Primary Gross Revenue],
   -- "prior 06 >> Primary TNT = Percent_Tourism on 06 and after > PRimary TNT = S_Percent_Tourism"
  case when SUBSTRING(assess.ASSESS_YEAR,0,CHARINDEX('/', assess.ASSESS_YEAR)) < '2006'then assess.PERCENT_TOURISM else assess.S_PERCENT_TOURISM end as [Primary Percent Tourism],
  assess.Payment_Overage as [Payment Overage],
  assess.PAYMENT_PLAN as [IMIS Payment Plan],
  assess.SECSEG_ASSESSMENT_RATE as 'Secondary Assessment Rate',
  assess.SECSEG_GROSSRECEIPTS as 'Secondary Gross Revenue',
  assess.READY_TO_POST as [IMIS Ready to Post],
  assess.SECSEG_PERCENT_TOURISM as 'Secondary Percent Tourism',
  --Find out category from code
  COALESCE(imis_seg_map.value_in_salesforce, acc.Segment_Code__C) as [Segment Code],
  -- Map Codes from IMIS to Codes in Salesforce
  COALESCE(imis_seg_map.category, acc.Segment_Category__C) as [Segment Category] ,
  assess.SEGMENT_MAX as 'Segment Max',
  assess.SIGNATURE as 'Signature',
  -- If Superseded = 1 then Get ID and Assess_year of Superseded = 1 record and search same Id and assess_year where Superseded = 0, the assess record you get will be populated here.
  --case when Superseded = 1 and assess1.sup_flag = 2 then first_value(SEQN) OVER(partition by  assess.id, assess.Assess_year ORDER by  Superseded )  else Null end as [Superseded By],
    LEAD(assess.SEQN) over(partition by assess.ID, assess.Assess_Year order by assess.SEQN, assess.Superseded DESC ) as [Supersede By],
  assess.Superseded as 'Superseded',
  assess.AdminFee as 'Total Admin Fees',
  assess.USE_SEG_MAX as 'Use Seg Max',
  assess.Under1M_Comment as [IMIS Under 1M Comment],
  assess.Vol_Assessment as 'Voluntary Assessment',
  assess.VOLUNTARY_MAX as [IMIS Voluntary Max],
  assess.seqn as [External Id]
  FROM
  IMIS.dbo.Assess assess 
   LEFT JOIN(select   id , ASSESS_YEAR,count(*) as [sup_flag] from IMIS.dbo.Assess   group by assess_year, id having count(*) > 1) assess1  on assess.id = assess1.id and assess.assess_year = assess1.assess_year 
  LEFT JOIN BOOMI_DEV.dbo.Email__c email ON assess.Contact_Email = email.NAME
  LEFT JOIN (select acc1.*, acc2.IMIS_ID__C as [IMIS_ID]  from BOOMI_DEV.dbo.PRODAccounts acc1 left join BOOMI_DEV.dbo.PRODAccounts  acc2 on acc1.BILL_TO_PARENT__C = acc2.ID) acc ON assess.ID = acc.TOURISM_ID__C
  LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  assess.segment = LTRIM(imis_seg_map.code_in_imis)
  LEFT JOIN IMIS.dbo.Assess_Notice assess_notice on assess.ID = assess_notice.ID and assess.ASSESS_YEAR = assess_notice.ASSESS_YEAR
--  LEFT JOIN IMIS.dbo.Assess_Audit assess_audit on assess.ID = assess_audit.ID and assess.ASSESS_YEAR = assess_audit.AuditYear
  LEFT JOIN IMIS.dbo.Name IMIS_name on assess.ID =  IMIS_name.ID) base
  LEFT JOIN BOOMI_DEV.dbo.SegmentRate rates on base.[Assess Year] = rates.[AssessYear] and base.[Segment Category] = rates.[SegmentCategory] 
  LEFT JOIN BOOMI_DEV.dbo.SegmentMax seg_max on base.[Assess Year] = seg_max.[PreviousFiscalYear] and base.[Segment Code] = seg_max.[SEGMENT_CODE__C]
  
	where base.[Assess Year] ! = '' and base.[Assess Year] ! = '2'  and base.[Status Flag] != 'D'
    )  
  Go

