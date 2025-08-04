# Raw Restaurant SEO Table

## Overview
This table creates the foundational dataset by flattening Google Search Console data from JSON format into a structured, row-per-keyword format suitable for analysis.

## Source Data
- **Source Table**: `PC_FIVETRAN_DB.DATA_OUTPUTS.HEX_CASE_GSC_EXPORT`
- **Data Type**: Google Search Console export via Fivetran
- **JSON Structure**: Nested JSON containing search performance metrics by keyword

## Table: `DEMO_DB.SANDBOX.RAW_RESTAURANT_SEO`

### Purpose
Transforms nested JSON Google Search Console data into a flat table where each row represents one keyword's performance for one restaurant on one day.

### Transformation Logic

#### Data Flattening
- Uses `LATERAL FLATTEN` to unnest JSON arrays in the `data:rows` field
- Extracts individual keyword performance metrics from nested structure
- Converts JSON data types to appropriate SQL data types

#### Data Quality Filtering
- **Status Filter**: `WHERE r.status = 'success'`
  - Only includes successful API calls to Google Search Console
  - Excludes failed API calls where `data` field would be NULL
  - Ensures data integrity and prevents processing errors

### Output Schema

| Column | Data Type | Description | Source |
|--------|-----------|-------------|---------|
| `restaurant_id` | STRING | Unique identifier for restaurant | `r.restaurant_id` |
| `domain` | STRING | Restaurant's website domain | `r.domain` |
| `_updated_at` | TIMESTAMP | When record was last updated | `r._updated_at` |
| `_created_at` | TIMESTAMP | When record was created | `r._created_at` |
| `clicks` | INTEGER | Number of clicks from search results | `value:"clicks"` |
| `ctr` | FLOAT | Click-through rate (clicks/impressions) | `value:"ctr"` |
| `impressions` | INTEGER | Number of times restaurant appeared in search results | `value:"impressions"` |
| `position` | FLOAT | Average ranking position in search results | `value:"position"` |
| `keyword` | STRING | Search term that generated the performance data | `value:"keys"[0]` |

### Key Design Decisions

1. **Keyword Extraction**: Uses `value:"keys"[0]` to extract the first (and typically only) keyword from the keys array
2. **Type Casting**: Explicitly casts JSON values to appropriate SQL types for performance and consistency
3. **Quality Gate**: Filters to `status = 'success'` to ensure only valid Google Search Console data is processed

### Data Granularity
- **One row per**: Restaurant + Keyword + Date combination
- **Time Period**: Determined by the source data export (typically 3-day periods)
- **Scope**: Only restaurants with successful Google Search Console API calls

### Example Output
```
restaurant_id | domain                    | clicks | impressions | position | keyword
12345        | spicefineindiancuisine.com |   6    |     84      |   2.26   | spice fine indian cuisine
12345        | spicefineindiancuisine.com |   4    |     24      |   2.38   | indian food near me
```

### Next Steps
This raw data feeds into:
1. `BASE_RESTAURANT_SEO` - Adds branded vs unbranded classification
2. Downstream analytics tables for restaurant and cuisine-level analysis

### Performance Notes
- `LATERAL FLATTEN` is optimized for Snowflake's architecture
- Filtering on `status = 'success'` reduces data volume and improves query performance
- Table is designed for efficient downstream joins and aggregations
