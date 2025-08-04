# Unified SEO Mart Table - The Analytics Powerhouse

## Overview
This is the **analytical table** of the data pipeline - a unified analytical mart that provides both restaurant-level and cuisine-level SEO performance analysis in a single, sustainable table structure. This approach eliminates the need for multiple tables while enabling comprehensive branded vs unbranded search analysis.

## Source Tables
- **Primary**: `DEMO_DB.SANDBOX.BASE_RESTAURANT_SEO` (SEO performance with branded classification)
- **Secondary**: `DEMO_DB.SANDBOX.BASE_RESTAURANT_CUISINE` (Restaurant cuisine classifications)

## Table: `DEMO_DB.SANDBOX.MART_RESTAURANT_SEO_UNIFIED`

###  Design Approach

#### The Problem with Traditional Approaches
Most analytics pipelines create separate tables for different aggregation levels:
- `MART_RESTAURANT_SEO` (restaurant-level metrics)
- `MART_CUISINE_SEO` (cuisine-level metrics)
- Multiple maintenance overhead, potential inconsistencies, hard to maintain single page reports/dashboards

#### The Unified Solution
**One table, two datasets, infinite possibilities.**

Uses a `dataset` column to vertically combine both aggregation levels:
- `dataset = 'restaurant'` → Restaurant-level performance metrics
- `dataset = 'cuisine'` → Cuisine-level performance metrics

### Architecture & Transformation Logic

#### Step 1: Restaurant Dataset (`restaurant_dataset`)
Aggregates SEO performance at the restaurant level:

```sql
SELECT 
    'restaurant' AS dataset,
    s.restaurant_id,
    s.domain,
    c.cuisines,                    -- Full cuisine array for context
    s.is_branded,
    s.date,
    COUNT(*) AS num_keywords,      -- Keywords this restaurant appeared for
    SUM(s.clicks) AS total_clicks,
    SUM(s.impressions) AS total_impressions,
    MEDIAN(s.position) AS median_position
```

**Business Value**: Enables restaurant-level analysis of branded vs unbranded performance.

#### Step 2: Cuisine Explosion (`cuisine_exploded`)
Explodes multi-cuisine restaurants into individual cuisine records:

```sql
SELECT 
    TRIM(f.value::STRING) AS cuisine_type,
    s.clicks,
    s.impressions,
    s.position
FROM BASE_RESTAURANT_SEO s
JOIN LATERAL FLATTEN(input => c.cuisines) f
```

**Example**: Restaurant serving ["italian", "pizza"] contributes to both Italian and Pizza cuisine metrics.

#### Step 3: Cuisine Dataset (`cuisine_dataset`)
Aggregates across all restaurants serving each cuisine type:

```sql
SELECT 
    'cuisine' AS dataset,
    NULL AS restaurant_id,         -- Not applicable at cuisine level
    ARRAY_CONSTRUCT(cuisine_type) AS cuisines,
    COUNT(DISTINCT restaurant_id) AS num_restaurants,
    SUM(clicks) AS total_clicks,
    MEDIAN(position) AS median_position
```

**Business Value**: Enables cuisine-level competitive analysis and market insights.

#### Step 4: Vertical Union (`combined_data`)
Combines both datasets into a unified structure:

```sql
SELECT * FROM restaurant_dataset
UNION ALL
SELECT * FROM cuisine_dataset
```

#### Step 5: Percentage Calculations (`final_with_percentages`)
Calculates branded vs unbranded percentages using dataset-specific logic:

```sql
CASE WHEN dataset = 'restaurant' THEN
    SUM(total_clicks) OVER (PARTITION BY restaurant_id, domain, date)
WHEN dataset = 'cuisine' THEN 
    SUM(total_clicks) OVER (PARTITION BY cuisine_type, date) 
END AS total_universal_clicks
```

### Output Schema

| Column | Data Type | Description | Restaurant Dataset | Cuisine Dataset |
|--------|-----------|-------------|-------------------|-----------------|
| `dataset` | STRING | Dataset identifier | `'restaurant'` | `'cuisine'` |
| `restaurant_id` | STRING | Restaurant identifier | ✅ Populated | ❌ NULL |
| `domain` | STRING | Restaurant domain | ✅ Populated | ❌ NULL |
| `cuisines` | ARRAY(STRING) | Cuisine classification | ✅ Full array | ✅ Single cuisine |
| `is_branded` | BOOLEAN | Search type classification | ✅ TRUE/FALSE | ✅ TRUE/FALSE |
| `date` | DATE | Performance date | ✅ Populated | ✅ Populated |
| `num_restaurants` | INTEGER | Restaurant count | ✅ Always 1 | ✅ Count per cuisine |
| `num_keywords` | INTEGER | Keyword count | ✅ Per restaurant | ✅ Per cuisine |
| `total_clicks` | INTEGER | Total clicks | ✅ Restaurant total | ✅ Cuisine total |
| `total_impressions` | INTEGER | Total impressions | ✅ Restaurant total | ✅ Cuisine total |
| `total_ctr` | FLOAT | Click-through rate | ✅ Restaurant CTR | ✅ Cuisine CTR |
| `median_position` | FLOAT | Median search position | ✅ Restaurant median | ✅ Cuisine median |
| `pct_of_clicks` | FLOAT | % of total clicks | ✅ Branded vs Unbranded | ✅ Branded vs Unbranded |
| `pct_of_impressions` | FLOAT | % of total impressions | ✅ Branded vs Unbranded | ✅ Branded vs Unbranded |

### Key Metrics Explained

#### Core Performance Metrics
- **Clicks**: User engagement - how many people clicked through to the restaurant
- **Impressions**: Visibility - how many search results the restaurant appeared in
- **CTR**: Efficiency - percentage of impressions that resulted in clicks
- **Position**: Ranking - where the restaurant typically appears in search results

#### Branded vs Unbranded Analysis
- **% of Clicks**: What portion of total restaurant/cuisine clicks come from branded searches
- **% of Impressions**: What portion of total visibility comes from branded searches

### Usage Patterns & Query Examples

#### Restaurant-Level Analysis
```sql
-- Restaurant branded vs unbranded performance
SELECT 
    restaurant_id,
    domain,
    date,
    is_branded,
    total_clicks,
    total_impressions,
    total_ctr,
    pct_of_clicks,
    pct_of_impressions
FROM DEMO_DB.SANDBOX.MART_RESTAURANT_SEO_UNIFIED 
WHERE dataset = 'restaurant'
ORDER BY restaurant_id, is_branded, date;
```

#### Cuisine-Level Analysis
```sql
-- Cuisine market analysis
SELECT 
    cuisines,
    date,
    is_branded,
    num_restaurants,
    total_clicks,
    median_position,
    pct_of_clicks
FROM DEMO_DB.SANDBOX.MART_RESTAURANT_SEO_UNIFIED 
WHERE dataset = 'cuisine'
ORDER BY cuisines, is_branded, date;
```

### Business Value & Strategic Insights

#### For Restaurant Owners
1. **Brand Health**: High branded % indicates strong brand recognition
2. **SEO Opportunities**: Low unbranded impressions suggest keyword optimization needs
3. **Competitive Position**: Compare performance vs cuisine averages
4. **Market Share**: Understand position within cuisine category

#### For Marketing Teams
1. **Budget Allocation**: Balance branded vs unbranded marketing spend
2. **Content Strategy**: Focus on cuisines with high unbranded opportunity
3. **Competitive Analysis**: Benchmark against cuisine-level performance
4. **ROI Measurement**: Track branded search improvement over time

#### For Data Teams
1. **Single Source of Truth**: One table for all SEO analytics
2. **Flexible Analysis**: Switch between restaurant and cuisine views seamlessly
3. **Consistent Metrics**: Same calculation logic across all aggregation levels
4. **Scalable Architecture**: Easy to add new dataset types, or segments (geography, restaurant type, etc.)

### Data Quality & Performance

#### Quality Assurance
- **Completeness**: Every restaurant appears in both branded and unbranded rows
- **Consistency**: Totals match between aggregation levels
- **Accuracy**: Percentage calculations always sum to 100% within groups

#### Performance Optimization
- **Efficient Partitioning**: Dataset column enables query pruning
- **Optimal Joins**: Single restaurant_id join path
- **Aggregation Strategy**: Pre-calculated percentages eliminate runtime calculations

### Sustainability & Maintenance

#### Why This Architecture Wins
1. **Single Code Base**: One table creation script instead of multiple
2. **Consistent Logic**: Same business rules across all analyses
3. **Easy Extensions**: Add new dataset types without architectural changes
4. **BI Tool Friendly**: Native filtering on dataset column
5. **Future Proof**: Scales with new requirements and data sources

#### Maintenance Checklist
- Monitor data freshness across both datasets
- Validate percentage calculations sum to 100%
- Check for missing cuisine classifications
- Verify branded classification accuracy periodically

---

## The Bottom Line

This unified mart table solves the core business challenge: **understanding restaurant SEO performance through the lens of search intent (branded vs unbranded) at multiple aggregation levels.** 

It's not just a table - it's a complete analytical framework that scales from individual restaurant optimization to market-wide strategic insights, all while maintaining a sustainable, single-source-of-truth architecture.

**This is the table that drives business decisions.**
