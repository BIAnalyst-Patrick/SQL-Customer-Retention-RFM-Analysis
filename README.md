# Customer Retention & RFM Segmentation Analysis (SQL)

**Industry**: E-commerce / Retail
**Tools**: SQL (SQLite — window functions, CTEs), Python (synthetic data generation)

---

## 🚀 Executive Summary

**Problem**: The business had no systematic view of which customers stay, which churn, and which segments actually drive revenue — retention and value were being assessed anecdotally rather than through structured cohort and RFM analysis.

**Action**: Modeled a relational e-commerce schema (customers, products, orders, order_items) covering 2,000 customers and 9,732 orders, then wrote a series of SQL queries using CTEs and window functions (`NTILE`, `RANK`, `ROW_NUMBER`, running `SUM() OVER`) to build monthly cohort retention curves, channel-level retention comparisons, RFM customer segmentation, and a lifetime-value Pareto analysis.

**Result**: Retention drops sharply after month 1 across every cohort (~95% → ~75% by month 1, ~45-55% by month 3), Referral customers retain nearly **2x better** than Social Media customers at month 3 (54.5% vs. 29.5%), and just **9.6% of customers ("Champions")** generate **19.4% of total revenue** — while 1,255 previously active customers (63% of the base) have gone quiet for 90+ days, including 186 high-value accounts at risk.

---

## 🎯 Problem Statement

**Core Issue**: Without cohort-level retention tracking or a formal customer-value segmentation, the business could not tell which acquisition channels produce loyal customers, which customers warrant retention spend, or how concentrated revenue is among top buyers.

**Key Questions**:
1. How does customer retention decay over time after signup, and does it vary by acquisition channel?
2. Which customers are most valuable (Recency, Frequency, Monetary), and how should they be segmented for targeted action?
3. What share of customers and revenue is at risk of churn right now?

---

## 📈 Objectives & Key Metrics

| Objective | Metric Tracked | Result Achieved |
|---|---|---|
| Quantify retention decay | Monthly cohort retention % | Drops from ~95% (month 0) to ~45-55% by month 3 across cohorts |
| Compare acquisition channel quality | Month-3 retention by channel | Referral: **54.5%** vs. Social Media: **29.5%** |
| Segment customers by value | RFM score → segment | 9.6% of customers ("Champions") drive **19.4%** of revenue |
| Identify revenue concentration | % of customers needed for 80% of revenue | **51.6%** of customers (less concentrated than the classic 80/20 assumption) |
| Flag churn risk | Customers inactive 90+ days | **1,255** flagged, including 186 high-value accounts |

---

## 📂 Data Overview

**Data Sources**: A synthetic but behaviorally realistic relational dataset (`data/generate_data.py` → `data/ecommerce.db`) — generated with intentional retention-decay and value-tier patterns so the SQL analysis surfaces genuine signal rather than random noise. Four tables: `customers`, `products`, `orders`, `order_items`.

**Key Variables**:
- **customers**: `signup_date`, `region`, `acquisition_channel`, `value_tier`
- **orders / order_items**: `order_date`, `quantity`, `unit_price` (joined to compute order-level and lifetime revenue)

**Scale**: 2,000 customers, 35 products across 6 categories, 9,732 orders, 24,438 order line items, **$7.4M** total revenue, spanning Jan 2023 – Dec 2024.

**Data Challenges**: As a synthetic dataset, it does not capture real-world noise (returns, refunds, fraud). It is designed specifically to demonstrate the SQL techniques (cohort analysis, window-function scoring, Pareto analysis) on a realistic schema rather than to represent a live business.

---

## 🔧 Methodology

**Schema Design** (`sql/00_schema.sql`): Standard normalized e-commerce schema — customers place orders, orders contain line items referencing products.

**Analysis Techniques**:
1. **Cohort Retention** (`sql/01_cohort_retention.sql`): CTEs compute each customer's signup cohort month and month-offset of every order, then aggregate into a retention matrix.
2. **Channel Retention Comparison** (`sql/02_retention_by_channel.sql`): Isolates month-3 retention by acquisition channel to compare customer quality, not just acquisition volume.
3. **RFM Segmentation** (`sql/03_rfm_segmentation.sql`, `sql/04_rfm_segment_summary.sql`): Uses `NTILE(4)` window functions to score every customer on Recency, Frequency, and Monetary value, then labels them into Champions / Loyal / At Risk / Lost segments.
4. **CLV & Pareto Analysis** (`sql/05_clv_pareto.sql`, `sql/06_pareto_threshold.sql`): Uses `RANK()` and a running `SUM() OVER (ORDER BY ...)` to rank customers by lifetime value and test the 80/20 rule against actual data.
5. **Churn Risk Flagging** (`sql/07_churn_risk.sql`): Flags customers with no order in 90+ days, prioritized by value tier.

**Tools**: SQL (SQLite dialect — directly portable to PostgreSQL/MySQL with minor date-function syntax changes), Python (`sqlite3`, used only for data generation and query execution, not analysis logic).

---

## 💡 Key Insights

#### Insight 1: Retention Decays Sharply in the First 90 Days, Then Stabilizes
**What**: Across nearly every monthly cohort, retention falls from ~90-97% in the signup month to ~70-85% by month 1, then to ~45-65% by month 3 — after which the decay rate slows.
**So What**: The first 90 days post-signup is the highest-leverage window for retention intervention (onboarding emails, early discounts, habit-forming touchpoints) — losses after month 3 are comparatively smaller and slower.

#### Insight 2: Acquisition Channel Quality Varies Nearly 2x
**What**: Referral customers retain at **54.5%** by month 3, Organic Search at **47.9%**, but Paid Ads (32.7%) and Social Media (29.5%) trail far behind.
**So What**: Channel performance should be judged on retained customers, not just acquisition cost or volume — shifting budget toward Referral programs (e.g., incentivized referral schemes) would likely improve long-term retention more than scaling paid acquisition.

#### Insight 3: A Small "Champions" Segment Disproportionately Drives Revenue
**What**: RFM segmentation shows Champions (9.6% of customers) generate 19.4% of revenue, and combined with Loyal Customers (26.3% of customers), the top two segments (35.9% of customers) account for **61.1% of total revenue**.
**So What**: Revenue is moderately concentrated — meaningful, but less extreme than a classic 80/20 split (it actually takes the top 51.6% of customers to reach 80% of revenue here). Retention efforts should prioritize Champions and Loyal Customers first, since losing them has outsized revenue impact.

#### Insight 4: A Majority of the Customer Base Has Gone Quiet
**What**: 1,255 of 1,988 active-at-some-point customers (63%) have not ordered in 90+ days, including 186 customers in the "high" value tier.
**So What**: This is a large, immediately actionable win-back opportunity — a targeted re-engagement campaign starting with the 186 high-value dormant accounts would protect the most revenue per outreach dollar.

---

## ✅ Recommendations & Business Impact

| Priority | Recommendation | Expected Impact | Owner |
|---|---|---|---|
| High | Launch win-back campaign targeting the 186 high-value customers inactive 90+ days | Directly protects revenue from the highest-risk, highest-value accounts | Retention / CRM Team |
| High | Build a 90-day onboarding journey (welcome series, early incentives) to address the steep month-1 retention drop | Targets the single largest retention drop-off point | Marketing / Lifecycle Team |
| Medium | Shift acquisition budget toward Referral programs given their ~2x retention advantage over Paid Ads/Social | Improves long-term customer quality, not just acquisition volume | Growth / Marketing Team |
| Medium | Build dedicated loyalty perks for the "Champions" and "Loyal Customers" RFM segments | Protects the 61.1% of revenue concentrated in these segments | Customer Success Team |
| Low | Re-run RFM segmentation monthly to track segment migration (e.g., Loyal → At Risk) | Turns this from a one-time snapshot into an ongoing retention early-warning system | Data/Analytics Team |

---

## 📉 Caveats & Next Steps

**Limitations**:
- Dataset is synthetic — generated with realistic but author-defined retention and value patterns, not collected from a live business. The SQL techniques and analytical approach are fully production-ready; the specific numbers reflect this dataset only.
- The 90-day churn-risk threshold is a simplifying assumption; a real deployment should validate this cutoff against actual repurchase-interval distributions.
- RFM quartile boundaries (`NTILE(4)`) are relative to this dataset's distribution and would need to be recalibrated against real order data.

**Next Steps**:
- Port the schema and queries to PostgreSQL with a scheduled job to refresh RFM segments and churn flags weekly.
- Layer in a basic CLV-prediction model on top of the RFM output to forecast future segment migration.
- Extend cohort analysis to track retention by region and product category, not just channel.

---

## 👤 Author

**Analyst:** Patrick Mwangi Gichuki
**Portfolio:** [https://gichuki.site](https://gichuki.site)
**LinkedIn:** [https://linkedin.com/in/patrick-gichuki-datascientist](https://linkedin.com/in/patrick-gichuki-datascientist)
