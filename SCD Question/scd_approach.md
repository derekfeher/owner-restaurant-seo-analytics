# Slowly Changing Dimensions (SCD) Methodology

## Overview
This document outlines the approach for handling restaurant cuisine changes over time using Slowly Changing Dimension Type 2 (SCD Type 2) methodology. This ensures accurate historical analysis when restaurants modify their cuisine classifications.

## Business Problem
Restaurants frequently change their cuisine offerings over time:
- A restaurant might start as "American" and later add "Italian" 
- Menu changes might result in complete cuisine reclassification
- Multiple changes can occur within a single day
- Historical SEO analysis must reflect the correct cuisine at the time of search performance

## SCD Type 2 Solution

### Table Structure: `BASE_RESTAURANT_CUISINES_HISTORICAL`

```sql
CREATE TABLE BASE_RESTAURANT_CUISINES_HISTORICAL AS (
SELECT
    restaurant_id STRING,
    cuisines ARRAY(STRING),
    valid_from DATE,
    valid_to DATE,          -- 2999-12-31 for current records
    is_current BOOLEAN
FROM raw_restaurant_cuisines_types
);
```

### Key Design Principles

#### 1. **One Row Per Change Period**
Each row represents a unique period when a restaurant had specific cuisine classifications:

| restaurant_id | cuisines | valid_from | valid_to | is_current |
|---------------|----------|------------|----------|------------|
| REST_001 | ["american"] | 2024-01-01 | 2024-01-02 | FALSE |
| REST_001 | ["chinese"] | 2024-01-03 | 2999-12-31 | TRUE |

#### 2. **Same-Day Change Consolidation**
When multiple cuisine changes occur within the same day, only the **latest change** is preserved:

**Raw Changes (Same Day):**
```
2024-01-03: american → italian → mexican → chinese
```

**Consolidated Result:**
```
chinese (2024-01-02 to 2999-12-31)
```

**Rationale:** Same-day changes typically represent data correction or rapid menu adjustments. The final state represents the restaurant's intended classification.

#### 3. **Future Date for Current Records**
- **Current records**: `valid_to = 2999-12-31`
- **Historical records**: `valid_to = actual_end_date`
- **Benefits**: Simplifies querying and eliminates NULL handling

### Integration with SEO Analysis

#### Historical Join Pattern
The SCD table integrates with SEO data using temporal joins:

```sql
FROM DEMO_DB.SANDBOX.BASE_RESTAURANT_SEO s
LEFT JOIN DEMO_DB.SANDBOX.BASE_RESTAURANT_CUISINES_HISTORICAL h
    ON s.restaurant_id = h.restaurant_id
    AND s.date BETWEEN h.valid_from AND h.valid_to
```

#### Join Guarantee
**Critical Design Feature:** This join pattern guarantees exactly **one match per restaurant per date** because:
- SCD table has non-overlapping validity periods for each restaurant
- Each SEO record date falls within exactly one validity period
- No gaps exist in the historical timeline (periods are contiguous)

### Example Scenario

#### Input: Restaurant Cuisine Changes
```
REST_123 Changes:
- Jan 1: ["american"]
- Jan 2: ["american"] (no change)
- Jan 3: ["american"] → ["italian"] → ["mexican"] → ["chinese"] (same day)
- Jan 4: (no change)
```

#### Output: SCD Historical Table
| restaurant_id | cuisines | valid_from | valid_to | is_current |
|---------------|----------|------------|----------|------------|
| REST_123 | ["american"] | 2024-01-01 | 2024-01-02 | FALSE |
| REST_123 | ["chinese"] | 2024-01-03 | 2999-12-31 | TRUE |

#### SEO Analysis Results
```sql
-- SEO data for REST_123 on Jan 2
-- Joins to: ["american"] cuisine (valid 2024-01-01 to 2024-01-02)

-- SEO data for REST_123 on Jan 4  
-- Joins to: ["chinese"] cuisine (valid 2024-01-03 to 2999-12-31)
```

### Business Benefits

#### 1. **Historical Accuracy**
- SEO performance is attributed to the correct cuisine at the time of search
- Enables accurate trend analysis across cuisine changes
- Prevents attribution errors in performance metrics

#### 2. **Simplified Analysis**
- Single join operation provides correct historical context
- No complex date logic required in analytical queries
- Consistent methodology across all time-series analysis

#### 3. **Data Quality**
- Same-day consolidation prevents data noise
- Guaranteed one-to-one join relationships
- Clear current vs historical record distinction

### Conclusion

The SCD Type 2 approach with same-day consolidation provides the optimal balance of:
- **Historical accuracy** for time-series analysis
- **Query simplicity** through guaranteed join relationships  
- **Data quality** via noise reduction
- **Performance** through optimized indexing strategies

This methodology ensures that restaurant SEO analysis reflects the accurate cuisine context at any point in time, enabling reliable business insights and trend analysis.
