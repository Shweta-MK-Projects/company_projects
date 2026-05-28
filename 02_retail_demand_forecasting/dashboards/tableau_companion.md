# Tableau Companion Dashboard Specifications

## LOD (Level of Detail) Calculations

To support assortment optimization and what-if scenarios across SKU/Region cuts, the following calculated fields are configured in the Tableau workbook:

### 1. Regional Assortment Category Sales (FIXED LOD)
Calculates total category sales inside a region regardless of the individual store or date filters on the worksheet.
```tableau
// Field Name: Regional_Category_Sales
{ FIXED [Region], [Category] : SUM([Net Revenue]) }
```

### 2. SKU Contribution to Region Category (FIXED LOD)
Evaluates a product's net sales weight relative to its broader category in the designated region.
```tableau
// Field Name: SKU_Regional_Contribution_Pct
SUM([Net Revenue]) / SUM({ FIXED [Region], [Category] : SUM([Net Revenue]) })
```

### 3. Store Safety Stock Deviation (EXCLUDE LOD)
Compares local store stock levels against SKU averages while ignoring local date fluctuations.
```tableau
// Field Name: Store_Stock_Vs_Avg
SUM([Stock On Hand]) - AVG({ EXCLUDE [Store Name], [Date] : AVG([Stock On Hand]) })
```

---

## Dynamic Dashboard Parameter Controls

1. **`p_Price_Adjustment_Multiplier`**
   * **Data Type:** Float
   * **Allowable Values:** Range from `-0.20` to `0.20` (step `0.05`)
   * **Description:** Governs what-if pricing adjustments to simulate demand elasticity curves.
2. **`p_Selected_Category_Target`**
   * **Data Type:** String
   * **Allowable Values:** Dynamic list populated from `Category`
   * **Description:** Filters regional tables to target performance views.

---

## AI-Assisted EDA (Exploratory Data Analysis) Prompts
These prompt templates are embedded in a dashboard "AI Insights Panel" to guide category managers during S&OP reviews:

* **Outlier Investigation Prompt:**
  > *"Analyze the monthly sales sequence for [Category] in the [Region] store network. Identify SKUs exhibiting demand shifts that exceed 2.0 standard deviations from the rolling 13-week baseline. Correlate with historical promotion calendars."*

* **Stockout Prevention Analysis:**
  > *"Given the current supplier lead time of [Supplier Lead Time] days and safety stock level of [Safety Stock Level] units, flag SKUs in the [Region] region facing a stockout threat within the next 3 weeks based on forecasted exponential smoothing demand."*
