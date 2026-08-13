# 🎬 Netflix Retention & Churn Analysis

**A SQL + Python deep-dive into why subscribers leave — and why "churn rate" alone is the wrong metric to chase.**

![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-Aggregation-003B57?logo=sqlite&logoColor=white)
![pandas](https://img.shields.io/badge/pandas-Analysis-150458?logo=pandas&logoColor=white)
![matplotlib](https://img.shields.io/badge/matplotlib-Visualization-11557C)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

---

## 📌 Overview

**Dataset:** 50,000 users × 24 monthly snapshots = **1,200,000 row-level records**, covering signups from January 2023 through November 2024. Fields include subscription plan, device type, country, monthly viewing hours, days since last login, and onboarding/retention milestone flags.

**Stack:** SQLite (`netflix.db`) for aggregation → pandas / matplotlib for analysis and visualization.

**What this project does:**
1. Collapses 1.2M row-level snapshots into a clean one-row-per-user summary table (`user_summary`)
2. Answers 8 concrete business questions a retention team would actually ask
3. Validates the results against an existing Power BI dashboard — and catches a real bug in it

---

## 📋 Key Findings

| # | Question | Finding |
|---|---|---|
| 1 | Overall churn & tenure | Churn hits **~99.7%** within 24 months — the useful metric is **tenure**, not churn rate |
| 2 | Plan tier vs. tenure | Premium users last **7.0 mo** vs. **5.0 mo** (Standard) vs. **3.6 mo** (Basic) — nearly **2x gap** |
| 3 | Revenue at risk | **Standard** drives the most revenue at risk (~$314K/mo) due to volume, despite shorter Premium tenure mattering more per-user |
| 4 | Engagement vs. retention | Retained users watch **~18% more** content and log in **~5 days** more recently |
| 5 | Cohort retention curve | Consistent **100% → 52% → 22%** drop-off at months 1/3/6 across **22 cohorts** — a structural issue, not a one-off |
| 6 | Onboarding funnel | Onboarding itself isn't the leak — **72% survive to month 3, 30% to month 6** is where the real churn happens |
| 7 | Household size vs. tenure | **No meaningful effect** — a hypothesis worth ruling out explicitly |
| 8 | Device type vs. churn | Churn rate is flat (**99.5–100%**) across Laptop / Mobile / TV — not a differentiator |

### 🔍 Bonus finding
The existing Power BI dashboard had **two data quality bugs** (a flat cohort heatmap and a triple-repeated retention number) — caught by independently rebuilding the same metrics from raw data and comparing.

---

## 🔭 What I'd Extend Next

- A **logistic regression or gradient-boosted churn-risk score** using the engagement (`avg_hours_watched`, `avg_days_since_login`) and tenure signals surfaced above, to flag at-risk accounts before they churn rather than after.
- A **corrected Power BI cohort heatmap**, built off the `user_summary` table, to replace the buggy one currently in production.
- Deeper segmentation of the **month 1→3 drop-off** (the steepest part of the curve) by acquisition channel or country, since that's where the biggest single retention lever likely sits.

---

## 🗂️ Repository Structure

```
netflix-retention-churn-analysis/
├── Netflix_Retention_Churn_Analysis.ipynb   # Full annotated analysis (SQL + Python + charts)
├── queries.sql                              # All SQL extracted & commented standalone
├── netflix.db.gz                            # Source SQLite database (gzip-compressed, ~47MB)
├── requirements.txt                         # Python dependencies
├── README.md                                # You are here
└── LICENSE
```

> **Note on data:** the raw `netflix.db` is 191 MB uncompressed, over GitHub's 100 MB file limit, so it's shipped gzip-compressed as `netflix.db.gz` (~47 MB). Unzip it before running the notebook:
> ```bash
> gunzip -k netflix.db.gz
> ```
> This produces `netflix.db` in the repo root, which the notebook's `sqlite3.connect('netflix.db')` call expects. It contains `users_raw` (1.2M row-level snapshots) and the derived `user_summary` table built in Step 1 of the notebook.

---

## 🧱 Data Schema

**`users_raw`** (1,200,000 rows — 50,000 users × 24 monthly snapshots)

| Column | Description |
|---|---|
| `user_id` | Unique subscriber ID |
| `country` | User's country |
| `subscription_plan` | Basic / Standard / Premium |
| `device_type` | Laptop / Mobile / TV |
| `age` | User age |
| `monthly_fee` | Subscription price for that plan |
| `join_date` | Signup date |
| `month_index` | Month number since signup (1–24) |
| `churned` / `churned_month` | Churn flags |
| `monthly_hours_watched` | Viewing hours for that month |
| `days_since_last_login` | Recency signal for that month |
| `number_of_profiles` | Household profile count |
| `stayed_after_3_months` / `stayed_after_6_months` | Retention milestone flags |

**`user_summary`** (derived, 50,000 rows — one per user) is built from `users_raw` in Step 1 of the notebook — see [`queries.sql`](queries.sql) for the exact `CREATE TABLE` logic.

---

## 🚀 Getting Started

```bash
git clone https://github.com/<vidhidagar25>/netflix_retention_churn_analysis.git
cd netflix-retention-churn-analysis
gunzip -k netflix.db.gz
pip install -r requirements.txt
jupyter notebook Netflix_Retention_Churn_Analysis.ipynb
```

---

## 🛠️ Tech Stack

- **SQLite** — aggregation and cohort logic at the database layer
- **pandas** — analysis and transformation
- **matplotlib** — custom Netflix-themed dark charts
- **Jupyter** — notebook-driven, narrative analysis

---

