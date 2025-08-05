# Restaurant SEO Analytics Pipeline

## Overview
This project builds a comprehensive data transformation pipeline to analyze restaurant SEO performance, specifically focusing on **branded vs unbranded search analysis**. The solution transforms raw Google Search Console data into actionable insights for GTM teams.

## 🎯 Business Problem
Restaurants need to understand:
- How much of their search traffic comes from brand recognition vs general searches
- Which cuisines perform better in branded vs unbranded searches  
- How to optimize their SEO strategy based on search intent

## 📊 Solution Architecture

### Unified Analytics Approach
Instead of creating separate tables for restaurant and cuisine analysis, this solution uses a **unified mart table** with a `dataset` column that enables:
- `dataset = 'restaurant'` → Restaurant-level metrics
- `dataset = 'cuisine'` → Cuisine-level metrics
- Single source of truth with consistent business logic
- Easy maintenance and extension

## 🚀 Quick Start

### 1. Create Tables (Run in Order)
```sql
-- Step 1: Extract raw data from JSON
raw_restaurant_seo.sql

-- Step 2: Add branded classification  
base_restaurant_seo.sql

-- Step 3: Clean cuisine data
base_restaurant_cuisine.sql

-- Step 4: Create unified analytics table
mart_restaurant_seo_unified.sql
```

### 2. Sample Queries

**Restaurant Analysis:**
```sql
SELECT 
    restaurant_id, domain, is_branded,
    total_clicks, total_impressions, total_ctr,
    pct_of_clicks, pct_of_impressions
FROM DEMO_DB.SANDBOX.MART_RESTAURANT_SEO_UNIFIED 
WHERE dataset = 'restaurant'
ORDER BY restaurant_id, is_branded;
```

**Cuisine Analysis:**
```sql
SELECT 
    cuisines[0]::STRING AS cuisine_type, is_branded,
    num_restaurants, total_clicks, median_position,
    pct_of_clicks, pct_of_impressions
FROM DEMO_DB.SANDBOX.MART_RESTAURANT_SEO_UNIFIED 
WHERE dataset = 'cuisine'
ORDER BY cuisine_type, is_branded;
```

## 🧠 Key Technical Decisions

### Branded vs Unbranded Classification
**Method:** Jaro-Winkler similarity algorithm with 80+ threshold
- **Why:** Handles real-world variations in restaurant name searches
- **Examples:** "spice fine indian cuisine" matches "spicefineindiancuisine.com"
- **Robustness:** Prevents false positives like "pho" matching "euphoria"

### Aggregation Choices
| Metric | Method | Rationale |
|--------|---------|-----------|
| **Clicks/Impressions** | `SUM()` | Want total performance volume |
| **CTR** | `DIV0(SUM(clicks), SUM(impressions))` | Accurate rate from aggregated totals |
| **Position** | `MEDIAN()` | Resistant to outliers |

**Why MEDIAN over AVERAGE for Position?**
- Search positions have extreme outliers (position 500+ for poor-ranking keywords)
- One outlier can destroy the average: `[2, 3, 1, 4, 2, 847] → avg = 143 `
- Median shows typical performance: `[2, 3, 1, 4, 2, 847] → median = 2.5 `
- **Business value:** "We typically rank position 3" vs "We rank position 143 on average"

### Data Architecture
- **Single table, multiple datasets** approach for scalability
- **Temporal joins** ready for historical analysis
- **Array handling** for multi-cuisine restaurants
- **Window functions** for efficient percentage calculations

## 📈 Business Insights Enabled

### Restaurant Level
- **Brand Health:** High branded % = strong brand recognition
- **SEO Opportunities:** Low unbranded visibility = keyword optimization needed
- **Performance Benchmarking:** Compare against cuisine averages

### Cuisine Level  
- **Market Analysis:** Which cuisines dominate branded vs unbranded searches
- **Competitive Intelligence:** Restaurant performance within cuisine categories
- **Content Strategy:** Focus optimization on high-opportunity cuisines

## 🔄 Historical Data Handling (SCD)

**Challenge:** Restaurants change cuisine types over time  
**Solution:** SCD Type 2 with temporal joins  
**Details:** See `SCD_Question/scd_approach.md`

**Key Features:**
- Non-overlapping validity periods
- Same-day change consolidation  
- Guaranteed one-to-one historical joins
- Future-date handling for current records

# Note
1- There are only 1k rows on the table `PC_FIVETRAN_DB.DATA_OUTPUTS.HEX_CASE_GSC_EXPORT`, with only 1 day of data , but the case study mentions 3 days worth of data.
