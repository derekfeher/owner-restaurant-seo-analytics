CREATE OR REPLACE TABLE DEMO_DB.SANDBOX.MART_RESTAURANT_SEO_UNIFIED AS
WITH 
-- Restaurant-level dataset
restaurant_dataset AS (
  SELECT 
    'restaurant' AS dataset,
    s.restaurant_id,
    s.domain,
    c.cuisines, -- Single-element array
    s.is_branded,
    s.date,
    1 AS num_restaurants, -- Always 1 for restaurant level
    COUNT(*) AS num_keywords,
    SUM(s.clicks) AS total_clicks,
    SUM(s.impressions) AS total_impressions,
    DIV0(SUM(s.clicks), SUM(s.impressions)) AS total_ctr,
    MEDIAN(s.position) AS median_position
  FROM DEMO_DB.SANDBOX.BASE_RESTAURANT_SEO s
  JOIN DEMO_DB.SANDBOX.BASE_RESTAURANT_CUISINE c
    ON s.restaurant_id = c.restaurant_id
  GROUP BY s.restaurant_id, s.domain, c.cuisines, s.is_branded, s.date
),

-- Cuisine-level dataset (exploded and aggregated)
cuisine_exploded AS (
  SELECT 
    s.restaurant_id,
    s.domain,
    s.date,
    s.is_branded,
    TRIM(f.value::STRING) AS cuisine_type,
    s.clicks,
    s.impressions,
    s.position
  FROM DEMO_DB.SANDBOX.BASE_RESTAURANT_SEO s
  LEFT JOIN DEMO_DB.SANDBOX.BASE_RESTAURANT_CUISINE c
    ON s.restaurant_id = c.restaurant_id
  LEFT JOIN LATERAL FLATTEN(input => c.cuisines) f
),

cuisine_dataset AS (
  SELECT 
    'cuisine' AS dataset,
    NULL AS restaurant_id, -- Not applicable for cuisine level
    NULL AS domain, -- Not applicable for cuisine level
    ARRAY_CONSTRUCT(cuisine_type) AS cuisines, -- Single-element array with cuisine
    is_branded,
    date,
    COUNT(DISTINCT restaurant_id) AS num_restaurants,
    COUNT(*) AS num_keywords,
    SUM(clicks) AS total_clicks,
    SUM(impressions) AS total_impressions,
    DIV0(SUM(clicks), SUM(impressions)) AS total_ctr,
    MEDIAN(position) AS median_position
  FROM cuisine_exploded
  GROUP BY cuisine_type,is_branded, date
),

-- Combine both datasets
combined_data AS (
  SELECT * FROM restaurant_dataset
  UNION ALL
  SELECT * FROM cuisine_dataset
),

-- Add percentage calculations for both datasets
final_with_percentages AS (
  SELECT 
    *,
    -- Calculate totals within each dataset grouping
    CASE WHEN dataset = 'restaurant' THEN
        SUM(total_clicks) OVER (PARTITION BY restaurant_id, domain, date)
         WHEN dataset = 'cuisine' THEN 
        SUM(total_clicks) OVER (PARTITION BY cuisines, date) 
    END AS total_universal_clicks,
    
    CASE WHEN dataset = 'restaurant' THEN
        SUM(total_impressions) OVER (PARTITION BY restaurant_id, domain, date)
         WHEN dataset = 'cuisine' THEN 
        SUM(total_impressions) OVER (PARTITION BY cuisines, date) 
    END AS total_universal_impressions,
  FROM combined_data
)

SELECT 
  dataset,
  restaurant_id,
  domain,
  cuisines,
  is_branded,
  date,
  num_restaurants,
  num_keywords,
  total_clicks,
  total_impressions,
  total_ctr,
  median_position,
  -- Percentage calculations
  DIV0(total_clicks, total_universal_clicks) AS pct_of_clicks,
  DIV0(total_impressions, total_universal_impressions) AS pct_of_impressions,
FROM final_with_percentages
ORDER BY dataset, restaurant_id, cuisines, is_branded, date
