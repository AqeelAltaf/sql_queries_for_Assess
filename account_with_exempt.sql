ALTER VIEW dbo.VW_IMIS_Account_with_Exempt as 
 select 
IMIS_Service.dbo.fn_TransParentID(Id, ASSESS_YEAR  ) as [Billing Entity],
Exempt_Code as [Exempt Status]
 from IMIS.dbo.Assess where Exempt_Code  in  ('Exempt - Business Size (Revenue) 5 years','Exempt - Business Size (Revenue) 3 years')