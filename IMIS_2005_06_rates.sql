ALTER VIEW dbo.VW_IMIS_2005_06_rates AS (select base.*,  imis_seg_map.value_in_salesforce [SegmentCode],
case when  base.MAX_ASSESSMENT_RATE >  base.MAX_S_ASSESSMENT_RATE then base.MAX_ASSESSMENT_RATE else base.MAX_S_ASSESSMENT_RATE end as Rate  from (
select SEGMENT , MAX(ASSESSMENT_RATE) as MAX_ASSESSMENT_RATE ,MAX(S_ASSESSMENT_RATE) as MAX_S_ASSESSMENT_RATE from IMIS.dbo.Assess where ASSESS_YEAR = '2005/06' GROUP BY SEGMENT) base
LEFT JOIN BOOMI_DEV.dbo.IMIS_to_sf_seg_map imis_seg_map ON  base.segment = LTRIM(imis_seg_map.code_in_imis))