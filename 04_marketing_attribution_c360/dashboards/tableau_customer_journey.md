# Tableau Customer Journey Funnel Specs

## Funnel Flow Visualizations
To evaluate customer touchpoint sequences leading to purchase conversions, the Tableau companion dashboard implements two custom journey charts:

### 1. Sankey Diagram (Multi-Channel Sequences)
A Sankey chart mapping customer movement through Touchpoint 1 (First Touch) $\rightarrow$ Touchpoint 2 $\rightarrow$ Touchpoint 3 $\rightarrow$ Checkout Conversion.
* **Nodes:** `Channel Name` representing the traffic source.
* **Sankey Polygons:** Calculated curve curves mapping flow volumes.
* **Calculated field for Node Positions:**
  ```tableau
  // Field Name: Node_Position
  CASE [Touchpoint Index]
    WHEN 1 THEN [Channel Name]
    WHEN 2 THEN [Channel Name]
    WHEN 3 THEN [Channel Name]
    ELSE 'Conversion'
  END
  ```

### 2. Conversions Funnel (Stage Drop-off Diagnostics)
Tracks users as they advance from Ad Click $\rightarrow$ Product page view $\rightarrow$ Add to Cart $\rightarrow$ Support interaction $\rightarrow$ Order Conversion.
* **Metrics:**
  * `Conversions_Count`: Count of unique converted sessions.
  * `Dropoff_Rate`: `(1 - (SUM([Conversions_Count]) / LOOKUP(SUM([Conversions_Count]), -1)))`

---

## Dynamic Slicers & Parameters

1. **`p_Attribution_Model`**
   * **Data Type:** String
   * **Allowable Values:** `First-Touch`, `Last-Touch`, `Linear`, `Time-Decay`
   * **Purpose:** Shifts bar volumes and ROI margins on charts dynamically by swapping the measure input:
     ```tableau
     // Field Name: Chosen_Attributed_Revenue
     CASE [p_Attribution_Model]
       WHEN 'First-Touch' THEN [Revenue First Touch]
       WHEN 'Last-Touch' THEN [Revenue Last Touch]
       WHEN 'Linear' THEN [Revenue Linear]
       WHEN 'Time-Decay' THEN [Revenue Time Decay]
     END
     ```
2. **`p_Session_Lookback_Days`**
   * **Data Type:** Integer
   * **Allowable Values:** Range `1` to `30`
   * **Purpose:** Truncates attribution evaluations to clicks occurring within X days prior to purchase.
