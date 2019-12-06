
--query to get all records which have more than two records with same id and assess_year
select   id , ASSESS_YEAR, count(id) from IMIS.dbo.Assess group by assess_year, id having count(*) > 2

-- query to get first record from the above query , you can change id and assess_year in case you want to check another row
select TOP 20 Superseded,*  from IMIS.dbo.Assess where ID = '1008177' and assess_year = '2014/15'

-- dont consider below query
--select Superseded,[Supersede By],* from BOOMI_DEV.dbo.VW_IMIS_assess where Account = '1008177' and [Assess Year] = '2014/15'



select count(*) from IMIS.dbo.Assess assess INNER JOIN BOOMI_DEV.dbo.email__c email on  assess.Contact_Email = email.name

select count(*)  from IMIS.dbo.Assess assess INNER JOIN BOOMI_DEV.dbo.PRODContacts cons on  assess.Contact_Email = cons.EXTERNAL_ID_VAL__C 
--



select  conts.STATUS__C,
--FIRST_VALUE(conts.STATUS__C) over partition by conts.STATUS__C order by status__c as [col],
*  from BOOMI_DEV.dbo.email__c email  inner join BOOMI_DEV.dbo.PRODContacts conts  on email.name = conts.EXTERNAL_ID_VAL__C ;


-- email deduplication query
WITH CTE AS 
(SELECT e.id,CONTACT__C,RN=ROW_NUMBER() OVER(PARTITION BY e.name order by  con.STATUS__C, cast(con.ID as varchar))
 FROM BOOMI_DEV.dbo.Email__c e inner join BOOMI_DEV.dbo.PRODContacts con  on e.name = con.EMAIL )
SELECT count(*)  FROM CTE WHERE RN=1


select * from (
SELECT con.STATUS__C,CONTACT__C,RN=ROW_NUMBER() OVER(PARTITION BY e.name order by  con.STATUS__C, cast(con.ID as varchar))
 FROM BOOMI_DEV.dbo.Email__c e inner join BOOMI_DEV.dbo.PRODContacts con  on e.name = con.EMAIL ) base where base.rn = 1




-- deduplication emial view 
ALTER VIEW  dbo.VW_IMIS_deduped_email
 AS (
 SELECT * from 
(SELECT e.name,con.STATUS__C, con.IMIS_CONTACT_NUMBER__C as [CONTACT__C],RN=ROW_NUMBER() OVER(PARTITION BY e.name order by  con.STATUS__C, cast(con.ID as varchar))
 FROM BOOMI_DEV.dbo.Email__c e  inner join BOOMI_DEV.dbo.PRODContacts con  on e.name = con.EMAIL ) email where email.rn = 1); 


--select count(*) from IMIS.dbo.Assess where ASSESS_YEAR != ''

/*select * from BOOMI_DEV.dbo.SegmentRateExtract;


select * from BOOMI_DEV.dbo.SegmentRateExtract;


select * from IMIS_to_sf_seg_map*/

-- query to get rows for which we don't have rates 
select  DISTINCT [Assess Year], [Segment Category] from BOOMI_DEV.dbo.VW_IMIS_Assess where [Primary Assessment Rate] is Null group by [Assess Year], [Segment Category]





-- queries to verify assess_car has right number of rows after name!='D' Logic
select count(*) from dbo.VW_IMIS_Assess_Car

select count(*) from IMIS.dbo.Assess_Car

select  count(*) from ( 
select assess_car.ID,IMIS_name.ID as[ID_],IMIS_name.Status  from IMIS.dbo.Assess_Car assess_car
LEFT JOIN IMIS.dbo.Name IMIS_name on assess_car.ID =  IMIS_name.ID )   base where base.Status != 'D'

-- queries to verify assess has right number of rows after name!='D' Logic
select count(*) from BOOMI_DEV.dbo.VW_IMIS_Assess

select count(*) from IMIS.dbo.Assess
select  count(*) from ( 
select assess.ASSESS_YEAR ,assess.ID,IMIS_name.ID as[ID_],IMIS_name.Status  from IMIS.dbo.Assess assess
LEFT JOIN IMIS.dbo.Name IMIS_name on assess.ID =  IMIS_name.ID )   base where base.Status != 'D' and  base.Assess_Year != ''

--for assess_audit


select count(*) from BOOMI_DEV.dbo.VW_IMIS_Assess_Audit

select count(*) from IMIS.dbo.Assess_Audit


select  count(*) from ( 
select Assess_Audit.ID,IMIS_name.ID as[ID_],IMIS_name.Status  from IMIS.dbo.Assess_Audit Assess_Audit
LEFT JOIN IMIS.dbo.Name IMIS_name on Assess_Audit.ID =  IMIS_name.ID )   base where base.Status != 'D'




select * from 
ass_aud.DecreaseRevenue as [7% Decrease in Revenue],	
ass_aud.DecreaseTNT as [7 Point Decrease in TNT],
case when ass_aud.DecreaseRevenue_Cleared != '' then 1 else 0 end as [Clear 7% Decrease in Revenue],
case when ass_aud.DecreaseTNT_Cleared != '' then 1 else 0 end as [Clear 7 Point Decrease in TNT],
case when ass_aud.LowTNT_Cleared != '' then 1 else 0  end as  [Clear Low TNT Reported],
case when ass_aud.RepeatRevenue_Cleared != '' then 1 else 0 end as [Clear Repeated Revenue],
ass_aud.RoundedRevenue_Cleared as  [Clear Rounded Revenue],
ass_aud.NoSecondTNT_Cleared as [Clear Secondary TNT],
ass_aud.NoTNT_Cleared as [Clear Zero TNT],
ass_aud.RepeatRevenue as [Repeated Revenue],
ass_aud.RoundedRevenue as [Rounded Revenue],
ass_aud.NoSecondTNT as [Secondary TNT]

IMIS.dbo.Assess_Audit ass_aud


