CREATE OR REPLACE TABLE DEMO_DB.SANDBOX.BASE_RESTAURANT_SEO AS

WITH

removing_domain_extension AS (
SELECT 
r.*,
REGEXP_REPLACE(
    REGEXP_REPLACE(
    -- Remove www. prefix
        REGEXP_REPLACE(UPPER(domain),'^(WWW\.)', ''), 
         -- Remove common extensions
        '\\.[a-zA-Z]{2,6}$', ''), 
    -- Replace hyphens and underscores with spaces
    '[-_]', ' '  
) AS clean_restaurant_name,
FROM DEMO_DB.SANDBOX.RAW_RESTAURANT_SEO AS r
),

jw_scoring AS (
SELECT 
r.*,
JAROWINKLER_SIMILARITY(clean_restaurant_name,keyword) AS jw_score,
IFF(JAROWINKLER_SIMILARITY(clean_restaurant_name,keyword) >= 80, TRUE,FALSE) AS is_branded
FROM removing_domain_extension AS r
)

SELECT
restaurant_id,
domain,
clicks,
ctr,
impressions,
position,
keyword,
is_branded,
DATE(_created_at) AS date,
FROM jw_scoring
