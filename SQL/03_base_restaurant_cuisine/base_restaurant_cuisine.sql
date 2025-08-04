CREATE OR REPLACE TABLE DEMO_DB.SANDBOX.BASE_RESTAURANT_CUISINE AS

WITH

cuisine_cleaning AS (
SELECT 
    restaurant_id,
    CASE 
        WHEN cuisines IS NULL OR cuisines = '[]' OR cuisines = ''
        THEN 'unknown'
        ELSE ARRAY_TO_STRING(PARSE_JSON(cuisines), ', ')
    END AS cuisines
FROM PC_FIVETRAN_DB.DATA_OUTPUTS.HEX_BRAND_CUISINE_EXPORT
)

SELECT
restaurant_id,
SPLIT(cuisines, ',') AS cuisines
FROM cuisine_cleaning
