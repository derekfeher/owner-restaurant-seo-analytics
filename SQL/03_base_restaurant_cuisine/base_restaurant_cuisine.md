# Base Restaurant Cuisine Table

## Overview
This table cleans and standardizes restaurant cuisine classification data, converting JSON arrays into structured arrays suitable for downstream analysis and BI tool integration.

## Source Data
- **Source Table**: `PC_FIVETRAN_DB.DATA_OUTPUTS.HEX_BRAND_CUISINE_EXPORT`
- **Data Format**: JSON arrays stored as VARCHAR containing cuisine classifications

## Table: `DEMO_DB.SANDBOX.BASE_RESTAURANT_CUISINE`

### Purpose
Transforms raw JSON cuisine data into a clean, analysis-ready format that enables:
- Cuisine-level performance analysis
- Multi-cuisine restaurant handling
- Efficient filtering and aggregation in BI tools

### Data Challenges Addressed

#### Raw Data Issues
The source data contains cuisine information in various formats:
```
[]                                                    # Empty - no cuisine data
[ "italian" ]                                        # Single cuisine
[ "bar-&-grill", "american", "breakfast", "cafe", "coffee" ] # Multiple cuisines
```

#### Data Quality Problems
1. **Inconsistent formats**: JSON arrays stored as text strings
2. **Empty values**: NULL, empty arrays, or empty strings
3. **Multi-value complexity**: Restaurants often serve multiple cuisine types
4. **BI tool compatibility**: Arrays need proper structure for filtering

### Transformation Logic

#### Step 1: Cuisine Cleaning (`cuisine_cleaning`)
Handles edge cases and converts JSON to comma-separated strings:

```sql
CASE 
    WHEN cuisines IS NULL OR cuisines = '[]' OR cuisines = ''
    THEN 'unknown'
    ELSE ARRAY_TO_STRING(PARSE_JSON(cuisines), ', ')
END AS cuisines
```

**Transformation Examples:**
- `NULL` → `'unknown'`
- `[]` → `'unknown'`
- `[ "italian" ]` → `'italian'`
- `[ "bar-&-grill", "american", "breakfast" ]` → `'bar-&-grill, american, breakfast'`

#### Step 2: Array Conversion
Converts comma-separated strings back to proper arrays:

```sql
SPLIT(cuisines, ',') AS cuisines
```

**Final Output Examples:**
- `'unknown'` → `['unknown']`
- `'italian'` → `['italian']`
- `'bar-&-grill, american, breakfast'` → `['bar-&-grill', 'american', 'breakfast']`

### Output Schema

| Column | Data Type | Description | Usage |
|--------|-----------|-------------|-------|
| `restaurant_id` | STRING | Unique restaurant identifier | Primary key for joins |
| `cuisines` | ARRAY(STRING) | Array of cuisine types served | Multi-value filtering and analysis |

### Key Design Decisions

#### 1. Array Structure Choice
**Decision**: Use ARRAY(STRING) instead of comma-separated strings
**Rationale**: 
- Enables efficient `LATERAL FLATTEN` operations for cuisine-level analysis
- Better performance for "contains" queries
- Native BI tool support for array filtering
- Maintains data type consistency

#### 2. Unknown Value Handling
**Decision**: Convert empty/null values to `['unknown']` 
**Rationale**:
- Prevents data loss in aggregations
- Enables complete restaurant coverage in analysis
- Clearly identifies restaurants with missing cuisine data
- Maintains array structure consistency

#### 3. Multi-Cuisine Approach
**Decision**: Preserve all cuisine types instead of selecting primary
**Rationale**:
- Reflects restaurant business reality (many serve multiple cuisines)
- Enables comprehensive cuisine-level analysis
- Allows for both individual and combined cuisine insights
- Supports flexible downstream filtering

### Business Value

#### Analytics Capabilities Enabled
1. **Cuisine Performance Analysis**: Compare SEO performance across cuisine types
2. **Multi-Cuisine Insights**: Understand how restaurants with multiple cuisines perform
3. **Market Coverage**: Identify cuisine gaps in restaurant portfolio
4. **Competitive Analysis**: Benchmark performance within specific cuisine categories

#### BI Tool Integration
The array structure supports:
- **Looker Studio**: Native array filtering capabilities
- **Tableau**: Array expansion for detailed analysis  
- **Power BI**: Multi-value filtering and drill-down
- **SQL Tools**: `LATERAL FLATTEN` for cuisine explosion

### Usage Patterns

#### Common Query Patterns

**Find restaurants serving specific cuisine:**
```sql
SELECT restaurant_id, cuisines
FROM DEMO_DB.SANDBOX.BASE_RESTAURANT_CUISINE
WHERE ARRAY_CONTAINS('italian'::VARIANT, cuisines);
```

**Explode for cuisine-level analysis:**
```sql
SELECT 
    restaurant_id,
    TRIM(f.value::STRING) AS individual_cuisine
FROM DEMO_DB.SANDBOX.BASE_RESTAURANT_CUISINE r
JOIN LATERAL FLATTEN(input => r.cuisines) f;
```

**Count restaurants by cuisine:**
```sql
SELECT 
    TRIM(f.value::STRING) AS cuisine_type,
    COUNT(DISTINCT restaurant_id) AS restaurant_count
FROM DEMO_DB.SANDBOX.BASE_RESTAURANT_CUISINE r
JOIN LATERAL FLATTEN(input => r.cuisines) f
GROUP BY cuisine_type
ORDER BY restaurant_count DESC;
```

### Data Quality Metrics

#### Coverage Statistics
- **Total restaurants**: Count of unique restaurant_id values
- **Known cuisines**: Restaurants where cuisines ≠ ['unknown']
- **Multi-cuisine**: Restaurants with ARRAY_SIZE(cuisines) > 1
- **Cuisine diversity**: COUNT(DISTINCT cuisine_type) across all restaurants

#### Validation Checks
1. **No NULL arrays**: All restaurants have at least one cuisine value
2. **Consistent formatting**: All cuisine values are trimmed strings
3. **Complete coverage**: Every restaurant_id from source data is present

### Performance Considerations

#### Optimization Features
- **Array indexing**: Efficient for ARRAY_CONTAINS operations
- **Flat structure**: Minimal storage overhead compared to normalized approach
- **Join efficiency**: Single restaurant_id key for downstream joins

#### Scalability Notes
- LATERAL FLATTEN operations scale linearly with data size
- Array operations are optimized in Snowflake's architecture
- Memory usage is proportional to average cuisines per restaurant

### Next Steps
This table enables:
1. **Cuisine-level analysis** in the unified mart table
2. **Multi-dimensional filtering** in BI tools
3. **Restaurant segmentation** by cuisine portfolio
4. **Market analysis** by cuisine category performance
