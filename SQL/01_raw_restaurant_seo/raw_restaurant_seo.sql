CREATE OR REPLACE TABLE DEMO_DB.SANDBOX.RAW_RESTAURANT_SEO AS

SELECT
    r.restaurant_id,
    r.domain,
    r._updated_at,
    r._created_at,
    value:"clicks"::INT AS clicks,
    value:"ctr"::FLOAT AS ctr,
    value:"impressions"::INT AS impressions,
    value:"position"::FLOAT AS position,
    value:"keys"[0]::STRING AS keyword
  FROM PC_FIVETRAN_DB.DATA_OUTPUTS.HEX_CASE_GSC_EXPORT AS r,
    LATERAL FLATTEN(input => PARSE_JSON(r.data):rows) AS f
  WHERE r.status = 'success'
