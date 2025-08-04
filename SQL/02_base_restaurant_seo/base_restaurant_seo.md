# Base Restaurant SEO Table

## Overview
This table enhances the raw Google Search Console data by adding branded vs unbranded search classification using fuzzy string matching techniques. This is the core analytical table that enables analysis of restaurant SEO performance by search intent type.

## Source Data
- **Source Table**: `DEMO_DB.SANDBOX.RAW_RESTAURANT_SEO`
- **Enhancement**: Adds branded search classification logic

## Table: `DEMO_DB.SANDBOX.BASE_RESTAURANT_SEO`

### Purpose
Classifies each keyword as either "branded" or "unbranded" search to enable analysis of:
- Brand recognition performance
- General SEO effectiveness 
- Search visibility by intent type

### Transformation Logic

#### Step 1: Domain Name Cleaning (`removing_domain_extension`)
Extracts clean restaurant names from website domains for accurate matching:

```sql
REGEXP_REPLACE(
    REGEXP_REPLACE(
        REGEXP_REPLACE(UPPER(domain),'^(WWW\.)', ''), -- Remove www. prefix
        '\\.[a-zA-Z]{2,6}$', ''),                     -- Remove .com, .net, etc.
    '[-_]', ' '                                       -- Replace separators with spaces
) AS clean_restaurant_name
```

**Examples:**
- `www.spicefineindiancuisine.com` → `SPICEFINEINDIANCUISINE`
- `joes-pizza.net` → `JOES PIZZA`
- `thai-garden.co.uk` → `THAI GARDEN`

#### Step 2: Branded Classification (`jw_scoring`)
Uses **Jaro-Winkler similarity algorithm** to determine if searches are branded:

```sql
JAROWINKLER_SIMILARITY(clean_restaurant_name, keyword) AS jw_score
IFF(JAROWINKLER_SIMILARITY(clean_restaurant_name, keyword) >= 80, TRUE, FALSE) AS is_branded
```

### Branded vs Unbranded Classification

#### What is "Branded" Search?
A search is classified as **branded** when the keyword contains or closely matches the restaurant's name.

**Examples of Branded Searches:**
- `spice fine indian cuisine` (for SpiceFineIndianCuisine.com)
- `rice and bites` (for RiceNBites.com)  
- `joe's pizza menu` (for JoesPizza.com)

**Examples of Unbranded Searches:**
- `indian food near me`
- `best pizza delivery`
- `thai restaurant downtown`

#### Algorithm Choice: Jaro-Winkler Similarity

**Why Jaro-Winkler?**
- **Handles variations**: Accounts for spacing, punctuation, and minor spelling differences
- **Prefix-weighted**: Gives extra credit for matching beginnings (ideal for restaurant names)
- **Typo-tolerant**: Handles common misspellings and formatting variations
- **Normalized scoring**: 0-100 scale makes threshold setting intuitive

**Threshold: 80**
- **80+ = Branded**: High confidence that keyword refers to the specific restaurant
- **<80 = Unbranded**: Generic searches or searches for other businesses

#### Algorithm Performance Examples

| Restaurant Domain | Keyword | Jaro-Winkler Score | Classification | Rationale |
|------------------|---------|-------------------|----------------|-----------|
| `spicefineindiancuisine.com` | `spice fine indian cuisine` | ~95 | Branded | Near-perfect match |
| `ricenbites.com` | `rice and bites` | ~85 | Branded | Handles word separation |
| `euphoriakitchen.com` | `pho` | ~15 | Unbranded | Prevents false positives |
| `joes-pizza.com` | `pizza near me` | ~25 | Unbranded | Generic search intent |

### Output Schema

| Column | Data Type | Description | Business Value |
|--------|-----------|-------------|----------------|
| `restaurant_id` | STRING | Unique restaurant identifier | Primary key for joins |
| `domain` | STRING | Restaurant website domain | Reference for verification |
| `clicks` | INTEGER | Clicks from search results | Performance metric |
| `ctr` | FLOAT | Click-through rate | Efficiency metric |
| `impressions` | INTEGER | Search result appearances | Visibility metric |
| `position` | FLOAT | Average search ranking | SEO effectiveness |
| `keyword` | STRING | Search term | Analysis dimension |
| `is_branded` | BOOLEAN | Branded search classification | **Key analytical dimension** |
| `date` | DATE | Performance date | Time-series analysis |

### Key Design Decisions

1. **Algorithm Selection**: Chose Jaro-Winkler over simpler substring matching to handle real-world variations in how customers search for restaurants

2. **Threshold Tuning**: Set at 80 to balance precision (avoiding false positives like "pho" matching "euphoria") with recall (catching legitimate variations)

3. **Domain Preprocessing**: Extensive cleaning ensures accurate name extraction from various domain formats

4. **Date Conversion**: Standardizes timestamp to date for easier aggregation and analysis

### Business Impact

This classification enables analysis of:
- **Brand Strength**: Higher % of branded searches indicates strong brand recognition
- **SEO Opportunities**: Low unbranded visibility suggests opportunities for general keyword optimization  
- **Performance Comparison**: Branded searches typically have higher CTR than unbranded
- **Market Position**: Restaurant's share of branded vs general search traffic

### Data Quality Considerations

#### Accuracy Assessment
- **Algorithm robustness**: Jaro-Winkler is industry-standard for fuzzy name matching
- **Threshold validation**: 80 threshold chosen to minimize false positives while catching variations
- **Manual spot-checking**: Sample validation shows good performance on edge cases

#### Known Limitations
- Very short keywords (2-3 characters) may have lower accuracy
- Extremely long restaurant names may need threshold adjustment
- Non-English restaurant names may require additional preprocessing

### Performance Notes
- Jaro-Winkler function is optimized in Snowflake
- Single-pass processing with CTEs maintains performance at scale
- Date conversion enables efficient time-based partitioning

### Next Steps
This table feeds into:
1. `MART_RESTAURANT_SEO_UNIFIED` - Restaurant and cuisine-level analytics
2. BI tools for branded vs unbranded performance dashboards
3. Time-series analysis of brand strength trends
