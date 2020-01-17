ALTER VIEW [dbo].[VW_IMIS_rev_Assess]
AS
 ( 
   select
[System IMIS Assess Cal],
base.[Account],
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
COALESCE(IMIS_Service.dbo.fn_TransParentID(base.Account, [Assess Year]), base.[Account]) as [Billing Entity],
[Completed],
[Complete],
[Completed By Contact],
[Completed Date],
[Customer Calculation],
[Exempt Status],
[Exempt Notes],
[Filed By User],
[Filed Online],
[Filed Date],
 [Interest Start Date],

--If Under_1M_End date is empty then create date with below logic day =1,Month=fiscal end month,Year=fiscal_year
--else Uner_1M_End date. Make sure format of date will be MM/DD/YYYY
case
    -- -- if FISCAL MONTH is not given make Fiscal End date with these  values 
    when (Under1M_EndDate is Null or Under1M_EndDate = '')  and  base.FISCAL_MONTH = '' and [Completed] = 0  and [Assess Year] = '2016/17' and   LOWER([Bill Cycle]) like 'jan%' then  '12/31/2016' 
    when (Under1M_EndDate is Null or Under1M_EndDate = '')  and  base.FISCAL_MONTH = '' and [Completed] = 0  and [Assess Year] = '2016/17' and   LOWER([Bill Cycle]) like 'jul%' then  '06/30/2016' 
     
    when (Under1M_EndDate is not  Null and Under1M_EndDate != '')   then FORMAT(Under1M_EndDate,'MM/dd/yyyy') 
  when TRY_CONVERT(date,CONCAT((base.[Fiscal Year]),'/',base.FISCAL_MONTH,'/','1')) is not null then FORMAT(EOMONTH(TRY_CONVERT(date,CONCAT((base.[Fiscal Year]),'/',base.FISCAL_MONTH,'/','1'))),'MM/dd/yyyy') 
  -- when both Fiscal Month and Fiscal year are '' then make 12 as end month default , assess year's first part in case of january and  assess year's first part minus one in case of january  
  when base.FISCAL_MONTH = '' and base.[Fiscal Year] = ''  and base.[Assess Year] >= '2017/18' and [Completed] = 0  and  LOWER([Bill Cycle]) like 'jan%' then  FORMAT(TRY_CONVERT(date,CONCAT('12','/','31','/',CONVERT(int,SUBSTRING(base.[Assess Year],0,CHARINDEX('/', base.[Assess Year])) ))) ,'MM/dd/yyyy')
  when base.FISCAL_MONTH = '' and base.[Fiscal Year] = ''  and base.[Assess Year] >= '2017/18' and [Completed] = 0  and  LOWER([Bill Cycle]) like 'jul%' then  FORMAT(TRY_CONVERT(date,CONCAT('12','/','31','/',(CONVERT(int,SUBSTRING(base.[Assess Year],0,CHARINDEX('/', base.[Assess Year])) )-1 ))) ,'MM/dd/yyyy')
  
  when base.FISCAL_MONTH = ''  and base.[Assess Year] >= '2017/18' and [Completed] = 0  and  LOWER([Bill Cycle]) like 'jan%' then  FORMAT(TRY_CONVERT(date,CONCAT('12','/','31','/',(base.[Fiscal Year]))),'MM/dd/yyyy') 
  when base.FISCAL_MONTH = '' and base.[Assess Year] >= '2017/18' and [Completed] = 0  and  LOWER([Bill Cycle]) like 'jul%' then  FORMAT(TRY_CONVERT(date,CONCAT('06','/','30','/',(base.[Fiscal Year]))) ,'MM/dd/yyyy')
       else '' end as [Fiscal End Date],

-- case when base.Fiscal_Month != '' then RIGHT('0'+base.Fiscal_Month,2) else null  end as [Fiscal End Month],
case when FISCAL_MONTH != '' then FORMAT(CONVERT(INT,[FISCAL_MONTH]), '00')  else '' end   as [Fiscal End Month],


--If Under_1M_Begin date is empty then create date with below logic day =1,Month=fiscal start month,Year=fiscal_year
-- else Uner_1M_Begin date. Make sure format of date will be MM/DD/YYYY "
case
    --  if FISCAL MONTH is not gicen make Fiscal Start datw with these  values 
    when (Under1M_BeginDate is Null or Under1M_BeginDate = '')  and base.FISCAL_MONTH = '' and [Completed] = 0  and [Assess Year] = '2016/17' and   LOWER([Bill Cycle]) like 'jan%' then  '01/01/2016' 
    when (Under1M_BeginDate is Null or Under1M_BeginDate = '')  and base.FISCAL_MONTH = '' and [Completed] = 0  and [Assess Year] = '2016/17' and   LOWER([Bill Cycle]) like 'jul%' then  '07/01/2015' 
    --else make it using Fical Month
    
    when  (Under1M_BeginDate is not Null and  Under1M_BeginDate != '') then FORMAT(Under1M_BeginDate ,'MM/dd/yyyy')
  when TRY_CONVERT(date,CONCAT(base.FISCAL_MONTH,'/','1','/',(base.[Fiscal Year]))) is not null then FORMAT(DATEADD(Month,-11,TRY_CONVERT(date,CONCAT(base.FISCAL_MONTH,'/','1','/',(base.[Fiscal Year])))),'MM/dd/yyyy') 
  when base.FISCAL_MONTH = '' and base.[Fiscal Year]  = '' and base.[Assess Year] >= '2017/18' and [Completed] = 0  and  LOWER([Bill Cycle]) like 'jan%' then FORMAT(TRY_CONVERT(date,CONCAT('01','/','01','/',CONVERT(int,SUBSTRING(base.[Assess Year],0,CHARINDEX('/', base.[Assess Year])) ))),'MM/dd/yyyy')
  when base.FISCAL_MONTH = '' and base.[Fiscal Year]  = '' and base.[Assess Year] >= '2017/18' and [Completed] = 0  and  LOWER([Bill Cycle]) like 'jul%' then  FORMAT(TRY_CONVERT(date,CONCAT('01','/','01','/',(CONVERT(int,SUBSTRING(base.[Assess Year],0,CHARINDEX('/', base.[Assess Year])) )-1 ))),'MM/dd/yyyy')
  when base.FISCAL_MONTH = '' and base.[Assess Year] >= '2017/18' and [Completed] = 0  and  LOWER([Bill Cycle]) like 'jan%'  then  FORMAT(TRY_CONVERT(date,CONCAT('01','/','01','/',(base.[Fiscal Year]))),'MM/dd/yyyy') 
  when base.FISCAL_MONTH = '' and base.[Assess Year] >= '2017/18' and [Completed] = 0  and  LOWER([Bill Cycle]) like 'jul%'  then  FORMAT(TRY_CONVERT(date,CONCAT('07','/','01','/',(base.[Fiscal Year])-1)) ,'MM/dd/yyyy')  
    else ''  end  as [Fiscal Start Date],


  --This means if 12 is start month then 12-1 will be nov
  case when base.FISCAL_MONTH > 0 and  base.FISCAL_MONTH < 12  then  FORMAT(CONVERT(INT,base.Fiscal_Month +1), '00') 
       when base.FISCAL_MONTH = 12 then '01' 
  else '' end as [Fiscal Start Month],
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
assess_audit_vw.[7% Decrease in Revenue],
assess_audit_vw.[7 Point Decrease in TNT],
assess_audit_vw.[Audit Year],
assess_audit_vw.[Low TNT],
assess_audit_vw.[Reason for Audit],
assess_audit_vw.[Repeated Revenue],
assess_audit_vw.[Rounded Revenue],
assess_audit_vw.[Secondary TNT],
assess_audit_vw.[Zero TNT],
assess_audit_vw.[IMIS Low TNT Cleared],
assess_audit_vw.[IMIS Low TNT Drop Code],
assess_audit_vw.[IMIS DecreaseRevenue Cleared] ,
assess_audit_vw.[IMIS DecreaseRevenue Drop Code],
assess_audit_vw.[IMIS DecreaseTNT Cleared],
assess_audit_vw.[IMIS DecreaseTNT Drop Code],
assess_audit_vw.[IMIS NoTNT Cleared],
assess_audit_vw.[IMIS NoTNT Drop Code],
assess_audit_vw.[IMIS RoundedRevenue Cleared],
assess_audit_vw.[IMIS RoundedRevenue Drop Code],
assess_audit_vw.[IMIS RepeatRevenue Cleared],
assess_audit_vw.[IMIS RepeatRevenue Drop Code],
assess_audit_vw.[Audit],
assess_audit_vw.[IMIS Secondary TNT Cleared],
assess_audit_vw.[IMIS Secondary TNT Drop Code],
assess_audit_vw.[Balance Due],
assess_audit_vw.[Balance Due Cleared],
assess_audit_vw.[Audit Note],
assess_audit_vw.[IMIS Miscalculation],
assess_audit_vw.[IMIS Miscalculation Cleared],
assess_audit_vw.[IMIS NAD Property],
assess_audit_vw.[IMIS Filing Notice Number],
assess_audit_vw.[IMIS Balance Notice Number],
assess_audit_vw.[IMIS Audit Notice Number],
assess_audit_vw.[IMIS Missed Projection Reason],
assess_audit_vw.[IMIS Below1Mil],
assess_audit_vw.[IMIS Below1mil_Cleared] ,
assess_audit_vw.[IMIS Writeoff Amount],
--[Fiscal Year],
[Assess Fiscal Month], 
[Assess Fiscal Year],
concat(base.[External Id],'-',base.[Account]) as [External Id]
 from
 (select
 assess.Fiscal_Month  as [Assess Fiscal Month], 
 assess.FISCAL_YEAR as [Assess Fiscal Year], 
 Under1M_BeginDate as Under1M_BeginDate,
 Under1M_EndDate as Under1M_EndDate,
 case when FISCAL_YEAR != '' then FISCAL_YEAR 
      when assess_fiscal.[Fiscal Year] != ''  and assess_fiscal.[Fiscal Year] is not Null  then convert(varchar(4),assess_fiscal.[Fiscal Year])
       
 else  ''  end  as [Fiscal Year],
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
  case when LOWER(assess.BILL_CYCLE) like 'jan%' then 'January'
       when LOWER(assess.BILL_CYCLE) like 'jul%' then 'July' 
       when assess.Assess_Year >= '2016/17' and assess.BILL_CYCLE = '' and assess.READY_TO_POST = 0   then acc.BILLING_CYCLE__C 
       else ''  end
       as [Bill Cycle],
  --Bring all accounts data in sql table, then search Assess.ID in tourism id field of account if account record is found then get data from bill_to_parent parent field and popultae here, if Bill_to_parent field is empty then populate acount tourism id
  --case when BILL_TO_PARENT__C is not Null then acc.IMIS_ID else acc.TOURISM_ID__C end as [Billing Entity],
  --COALESCE(acc.BILL_TO_PARENT__C,(str(acc.TOURISM_ID__C))) as [Billing Entity],
  
  assess.[READY_TO_POST] as [Completed],
  assess.[COMPLETE] as [Complete],
  -- this is old logic 
  -- If completed date is not blank mark this true
  -- case when assess.DATE_RECEIVED is not null then 'True' else 'False'  end as [Completed] ,
  -- Bring all contacts and email object data in sql tables then search contact email in email table if email found then get the contact record of this email and populate in this field
  email.CONTACT__R#IMIS_CONTACT_NUMBER__C as [Completed By Contact],
  FORMAT (assess.DATE_RECEIVED , 'MM/dd/yyyy') as [Completed Date],
  assess.ASSESSMENT_LOC as [Customer Calculation],
-- new changes as of 12/12/2019
  case  when assess.Exempt_Code in ('B200','CEASED','NOTSEG','PBBODY','SECXEA','SECXEE','VOL') then   'Exempt – Other'   
        when assess.Exempt_Code in ('MVDOUT','NOTOUR','UNDER1','UNDER8','UNDR1','UNDR20','UNDR50') then   'Exempt – Business Size (Revenue) 1 year'
        when assess.Exempt_Code  = 'NN' then 'Exempt – Non Noticed' 
        else '' end
        as [Exempt Status],
  assess.Exempt_Note as [Exempt Notes],
  --Bring all contacts and email object data in sql tables then search contact email in email table if email found then get the contact record of this email and populate in this field
  email.CONTACT__R#IMIS_CONTACT_NUMBER__C as [Filed By User],
  Format(assess.DATE_RECEIVED,'MM/dd/yyyy') as [Filed Date],
  Format(assess_notice.N_DueDate,'MM/dd/yyyy') as [Interest Start Date],
  assess.Filed_online as 'Filed Online',
  case when assess.Fiscal_Month != '' then RIGHT('0'+assess.Fiscal_Month,2)  
  when assess.FISCAL_MONTH = '' and assess.ASSESS_YEAR >= '2017/18' and assess.READY_TO_POST = 0   then 
      FIRST_VALUE( assess.FISCAL_MONTH ) OVER ( 
        PARTITION BY assess.Id
        ORDER BY assess.ASSESS_YEAR DESC,
                case when assess.ASSESS_YEAR < '2016/17' or Superseded = 1 then '' ELSE FISCAL_MONTH end ASC
	      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) 
     
    else ''  end as [Fiscal_Month],
  assess.GROSS_RECEIPTS as 'Gross Reciept',
  --All the exempt codes will be mapped to "Exempt – Other" picklist value except UNDER1  and NOTOUR, in case of these set IMIS assessment cal to 0 and keep these codes as is in this picklist
  case when assess.Exempt_Code not in  ('NOTOUR','UNDER1') then  assess.ASSESSMENT_CALC  else  0  end as [IMIS Assessment Calculation],
  assess.ASSESSMENT_CALC as [System IMIS Assess Cal],
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
  LEFT JOIN BOOMI_DEV.dbo.VW_IMIS_Asess_Fiscals assess_fiscal on  assess.SEQN = assess_fiscal.SEQN and  assess.ID = assess_fiscal.ID and assess.ASSESS_YEAR = assess_fiscal.Assess_Year and assess.SEQN = assess_fiscal.SEQN   
  LEFT JOIN (select acc1.*, acc2.IMIS_ID__C as [IMIS_ID]  from BOOMI_DEV.dbo.PRODAccounts acc1 left join BOOMI_DEV.dbo.PRODAccounts  acc2 on acc1.BILL_TO_PARENT__C = acc2.ID) acc ON assess.ID = acc.TOURISM_ID__C
  LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  assess.segment = LTRIM(imis_seg_map.code_in_imis)
  LEFT JOIN IMIS.dbo.Assess_Notice assess_notice on assess.ID = assess_notice.ID and assess.ASSESS_YEAR = assess_notice.ASSESS_YEAR
  --LEFT JOIN BOOMI_DEV.dbo.VW_IMIS_Assess_Audit assess_audit_vw on assess.ID = assess_audit_vw.Account and assess.ASSESS_YEAR = assess_audit_vw.[Audit Year]
  LEFT JOIN IMIS.dbo.Name IMIS_name on assess.ID =  IMIS_name.ID) base
  LEFT JOIN BOOMI_DEV.dbo.VW_IMIS_Assess_Audit assess_audit_vw on base.Account= assess_audit_vw.Account and base.[Assess Year] = assess_audit_vw.[Audit Year]
  LEFT JOIN BOOMI_DEV.dbo.SegmentRate rates on base.[Assess Year] = rates.[AssessYear] and base.[Segment Category] = rates.[SegmentCategory] 
  LEFT JOIN BOOMI_DEV.dbo.SegmentMax seg_max on base.[Assess Year] = seg_max.[PreviousFiscalYear] and base.[Segment Code] = seg_max.[SEGMENT_CODE__C]
  
	where base.[Assess Year] ! = '' and base.[Assess Year] ! = '2'  and base.[Status Flag] != 'D'
    )  

GO