# Exploratory & Advanced Analytics on a Sales Data Warehouse (SQL Server)

SQL analysis of the **gold layer** of my [SQL Data Warehouse project](../README.md): exploratory analysis, time-series and performance analysis, segmentation, and two reusable reporting views, all in T-SQL.

## Business Problem

A company that sells bikes, accessories, and clothing to customers in several countries needs to understand its sales business before building dashboards:

- How big is the business and how much history does the data cover?
- Where do customers come from, and which categories and products drive revenue?
- How are sales trending over time, and is growth steady or seasonal?
- Which products are growing or declining year over year?
- Which customers are the most valuable, and which products are high or low performers?
- Can the numbers be trusted (for example, are orders being counted correctly)?

Skipping this step is how reports end up built on misunderstood data. Every answer here comes directly from the warehouse using SQL.

## Dataset

Queried from the warehouse **gold layer** (star schema):

| Object | Type | Grain |
|---|---|---|
| `Gold.fact_sales` | Fact view | One row per **order line** |
| `Gold.dim_customers` | Dimension view | One row per customer |
| `Gold.dim_products` | Dimension view | One row per product |

![Gold layer objects](images/gold-layer-objects.png)

Orders run from **2010-12-29 to 2014-01-28** (37 months). **2010 and 2014 are partial years** (a few days and one month), so they should not be compared with 2011 to 2013 as full years.

## Repository Structure

```
eda/
├── README.md
├── 01_EDA.sql                  Exploration, magnitude, ranking
├── 02_Advanced_EDA.sql         Trends, cumulative, performance, part-to-whole, segmentation
├── reports/
│   ├── report_customers.sql    View: Gold.report_customers
│   └── report_products.sql     View: Gold.report_products
└── images/                     Screenshots used in this README
```

## Part 1: Exploratory Analysis (`01_EDA.sql`)

| # | Section | Purpose |
|---|---|---|
| 1 | Database exploration | Inspect tables and columns |
| 2 | Dimensions exploration | Countries, categories, products |
| 3 | Date exploration | Time span of data, customer age range |
| 4 | Measures exploration | Headline business metrics |
| 5 | Magnitude exploration | Measures broken down by dimension |
| 6 | Ranking analysis | Top and bottom performers |
| 7 | Ranking with window functions | `ROW_NUMBER`, `RANK`, `DENSE_RANK` and tie handling |

### Key Business Metrics

| Metric | Value |
|---|---|
| Total sales | 29,356,250 |
| Total quantity sold | 60,423 |
| Average selling price | 486 |
| Total orders (distinct) | 27,659 |
| Total products | 295 |
| Customers with at least one order | 18,484 |
| Average revenue per order | about 1,061 |

*Amounts are in the currency units stored in the source data.*

### Findings

**1. Revenue is almost entirely bikes.**

| Category | Revenue | Share |
|---|---|---|
| Bikes | 28,316,272 | 96.5% |
| Accessories | 700,262 | 2.4% |
| Clothing | 339,716 | 1.2% |

**2. Five Mountain-200 variants generate about 6.67 million, roughly 22.7% of all revenue**, from 5 of 295 products.

| Rank | Product | Revenue |
|---|---|---|
| 1 | Mountain-200 Black-46 | 1,373,454 |
| 2 | Mountain-200 Black-42 | 1,363,128 |
| 3 | Mountain-200 Silver-38 | 1,339,394 |
| 4 | Mountain-200 Silver-46 | 1,301,029 |
| 5 | Mountain-200 Black-38 | 1,294,854 |

**3. The lowest-selling products are low-priced accessories** (Racing Socks-L at 2,430, Racing Socks-M at 2,682, Patch Kit/8 Patches at 6,382). Only products with at least one sale appear, because the query starts from the fact table.

**4. Customers are concentrated in the United States** (7,482 of 18,484, about 40.5%). The US plus Australia is about 60%. **337 customers (1.8%)** have no country recorded.

**5. Counting rows overstates orders.** `COUNT(order_number)` returned 60,398 but `COUNT(DISTINCT order_number)` returned 27,659, because the fact table stores one row per order line (for example order `SO57282` has 3 rows). All order metrics use `COUNT(DISTINCT order_number)`.

**6. `TOP 10` hides ties.** The most active customers placed 28 orders, and at least eight more tied at 27. With `TOP 10`, which tied customers appear is arbitrary. Using `DENSE_RANK()` keeps every tied customer.

| customer_key | Name | Orders | ROW_NUMBER | RANK | DENSE_RANK |
|---|---|---|---|---|---|
| 177 | Mason Roberts | 28 | 1 | 1 | 1 |
| 92 | Dalton Perez | 28 | 2 | 1 | 1 |
| 331 | Ryan Thompson | 27 | 3 | 3 | 2 |
| 301 | Fernando Barnes | 27 | 4 | 3 | 2 |

## Part 2: Advanced Analytics (`02_Advanced_EDA.sql`)

| Section | Question answered | Techniques |
|---|---|---|
| Change over time | How do sales, quantity and customers move by month and year? | `YEAR`, `MONTH`, `DATEFROMPARTS`, `COUNT(DISTINCT)` |
| Cumulative analysis | What is the running total, and the 3-month moving average price? | `SUM() OVER`, `AVG() OVER (ROWS BETWEEN ...)` |
| Performance analysis | Is each product above or below its own average, and growing or shrinking vs last year / last month? | CTEs, `AVG() OVER (PARTITION BY)`, `LAG` |
| Part-to-whole | Which categories contribute most to sales? | `SUM() OVER ()` for the grand total |
| Data segmentation | How are products grouped by cost and customers by value? | `CASE`, CTEs |

> **Technical note.** An `AVG() OVER (ORDER BY ...)` with no frame is a *cumulative* average, not a moving average. The 3-month moving average uses `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW`. Likewise, a product's overall average uses `PARTITION BY` with **no** `ORDER BY`, otherwise it becomes a running average.

### Findings

> Fill the values from your query results before publishing. Keep each finding to the number plus one sentence on what it means.

**1. Yearly trend.**

| Year | Total sales | Running total |
|---|---|---|
| 2010 (partial) | ___ | ___ |
| 2011 | ___ | ___ |
| 2012 | ___ | ___ |
| 2013 | ___ | ___ |
| 2014 (partial) | ___ | ___ |

Insight: ___ (for example, growth from 2011 to 2013 and which year drove it).

**2. Monthly pattern.** Best month: ___ (___). Weakest full month: ___ (___). Moving average price trend: ___.

**3. Product performance.** ___ products finished above their own average in their latest full year. The biggest year-over-year increase was ___ (+___) and the biggest decrease was ___ (-___).

**4. Part-to-whole.** Bikes account for ___% of sales, matching the 96.5% from Part 1.

**5. Product cost segments.**

| Cost segment | Products |
|---|---|
| Below 100 | ___ |
| 100 - 499 | ___ |
| 500 - 999 | ___ |
| 1000 and above | ___ |

**6. Customer segments.**

| Segment | Customers | Share |
|---|---|---|
| VIP | ___ | ___% |
| Regular | ___ | ___% |
| New | ___ | ___% |

Insight: ___ (for example, what share of revenue the VIP group generates; check with `report_customers`).

## Part 3: Reporting Views (`reports/`)

Two reusable views that package the analysis for Power BI or other tools.

**`Gold.report_customers`**: one row per customer with age group, segment (VIP / Regular / New), total orders, sales, quantity, products, lifespan in months, and KPIs: recency, average order value, average monthly spend.

**`Gold.report_products`**: one row per product with category, cost, segment (High Performer above 50,000 / Mid-Range 10,000 to 50,000 / Low Performer), orders, customers, quantity, sales, lifespan, and KPIs: recency, average selling price, average order revenue, average monthly revenue.

Design decisions:
- **Recency is measured from the last order date in the data**, not `GETDATE()`. The data ends in January 2014, so using today's date would show every customer as inactive for over a decade.
- Averages are cast to `DECIMAL` to avoid integer division truncating results.
- Customers with no birthdate get an `Unknown` age group instead of falling into the oldest group.

## Insights and Recommendations

1. **Concentration risk.** About 96.5% of revenue is bikes. Check whether accessories and clothing are being sold alongside bikes, since they are a possible growth area.
2. **Protect the Mountain-200 line.** Pricing, stock and supply issues on one product line move roughly a fifth of revenue.
3. **Read the bottom-5 list carefully.** Socks and patch kits are low-priced, so low revenue does not mean low importance. Check quantity and margin before dropping a product.
4. **Fix missing countries upstream.** The 337 customers with country `n/a` could be handled in the silver layer.
5. **Always count `DISTINCT order_number`.** Any dashboard on this fact table must do the same, or orders are overstated by more than double.
6. **Use segments to target retention.** ___ (complete after you see the VIP and New numbers).

## How to Run

1. Build the warehouse using the scripts in this repository (bronze, silver, gold).
2. Confirm `Gold.fact_sales`, `Gold.dim_customers` and `Gold.dim_products` exist.
3. Run `01_EDA.sql` and `02_Advanced_EDA.sql` in SQL Server Management Studio, one section at a time.
4. Run the two files in `reports/` to create the views, then `SELECT * FROM Gold.report_customers`.

**Tools:** SQL Server, T-SQL, SSMS

## Limitations and Next Steps

- Results describe a sample dataset from 2010 to 2014 and are not current business figures.
- Partial years (2010, 2014) limit year-over-year conclusions; monthly analysis is more reliable at the edges.
- Segment thresholds (12 months, 5,000 sales, 50,000 / 10,000 revenue) are rule-of-thumb values, not statistically derived.
- Next step: connect **Power BI** to `Gold.report_customers` and `Gold.report_products` and build an interactive dashboard.

## Acknowledgements

The structure follows the EDA and advanced analytics modules of the *Data with Baraa* SQL course. The validation checks, tie-handling analysis, script corrections, findings and recommendations are my own write-up.

## Author

**Femila Abdul Kareem** (GitHub: [FemAbdul](https://github.com/FemAbdul))
