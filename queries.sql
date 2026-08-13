/* ==========================================================================
   Netflix Retention & Churn Analysis — Annotated SQL
   Source: netflix.db (SQLite)
   Raw table: users_raw       -> 1,200,000 rows (50,000 users x 24 monthly snapshots)
   Derived table: user_summary -> 50,000 rows (one row per user)
   ========================================================================== */


/* --------------------------------------------------------------------------
   STEP 1 — Collapse the row-level snapshot table into one row per user.
   Every downstream question in this analysis runs off `user_summary`.
   -------------------------------------------------------------------------- */
CREATE TABLE user_summary AS
SELECT
    user_id,
    MIN(country)                                            AS country,
    MIN(subscription_plan)                                  AS plan,
    MIN(device_type)                                        AS device_type,
    MIN(age)                                                AS age,
    MIN(monthly_fee)                                        AS monthly_fee,
    substr(MIN(join_date), 1, 7)                            AS cohort_month,
    MAX(churned)                                            AS ever_churned,
    MIN(CASE WHEN churned_month = 1 THEN month_index END)   AS churn_month,
    AVG(monthly_hours_watched)                              AS avg_hours_watched,
    AVG(days_since_last_login)                              AS avg_days_since_login,
    MAX(stayed_after_3_months)                              AS stayed_3mo,
    MAX(stayed_after_6_months)                              AS stayed_6mo
FROM users_raw
GROUP BY user_id;


/* --------------------------------------------------------------------------
   Q1 — Overall churn rate & average tenure
   Finding: churn hits ~99.7% within the 24-month window, so churn *rate*
   is nearly meaningless here — tenure (avg_months_to_churn) is the metric
   that actually differentiates users.
   -------------------------------------------------------------------------- */
SELECT
    COUNT(*)                                    AS total_users,
    ROUND(100.0 * AVG(ever_churned), 2)         AS churn_rate_pct,
    ROUND(AVG(churn_month), 1)                  AS avg_months_to_churn
FROM user_summary;


/* --------------------------------------------------------------------------
   Q2 — Tenure by subscription plan
   Finding: Premium (7.0 mo) vs Standard (5.0 mo) vs Basic (3.6 mo) —
   nearly a 2x gap in how long users stick around by tier.
   -------------------------------------------------------------------------- */
SELECT
    plan,
    COUNT(*)                                    AS users,
    ROUND(100.0 * AVG(ever_churned), 2)         AS churn_rate_pct,
    ROUND(AVG(churn_month), 1)                  AS avg_months_to_churn
FROM user_summary
GROUP BY plan
ORDER BY avg_months_to_churn;


/* --------------------------------------------------------------------------
   Q3 — Monthly revenue at risk by plan
   Finding: Standard drives the most revenue at risk (~$314K/mo) purely
   on volume, even though Premium users individually churn slower.
   -------------------------------------------------------------------------- */
SELECT
    plan,
    COUNT(*)                                    AS churned_users,
    ROUND(SUM(monthly_fee), 2)                  AS monthly_revenue_at_risk
FROM user_summary
WHERE ever_churned = 1
GROUP BY plan
ORDER BY monthly_revenue_at_risk DESC;


/* --------------------------------------------------------------------------
   Q4 — Engagement vs. retention
   Finding: retained users watch ~18% more content (45.6 vs 38.6 hrs/mo)
   and logged in ~5 days more recently than churned users.
   -------------------------------------------------------------------------- */
SELECT
    CASE ever_churned WHEN 1 THEN 'Churned' ELSE 'Retained' END AS segment,
    COUNT(*)                                    AS users,
    ROUND(AVG(avg_hours_watched), 2)            AS avg_monthly_hours_watched,
    ROUND(AVG(avg_days_since_login), 2)         AS avg_days_since_last_login
FROM user_summary
GROUP BY ever_churned;


/* --------------------------------------------------------------------------
   Q5 — Cohort retention curve (month 1 / 3 / 6)
   Finding: a consistent 100% -> 52% -> 22% drop-off across 22 monthly
   cohorts spanning ~2 years — a structural pattern, not a one-off blip.
   -------------------------------------------------------------------------- */
SELECT
    cohort_month,
    COUNT(*) AS cohort_size,
    ROUND(100.0 * SUM(CASE WHEN ever_churned = 0 OR churn_month > 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS retained_month1_pct,
    ROUND(100.0 * SUM(CASE WHEN ever_churned = 0 OR churn_month > 3 THEN 1 ELSE 0 END) / COUNT(*), 1) AS retained_month3_pct,
    ROUND(100.0 * SUM(CASE WHEN ever_churned = 0 OR churn_month > 6 THEN 1 ELSE 0 END) / COUNT(*), 1) AS retained_month6_pct
FROM user_summary
GROUP BY cohort_month
ORDER BY cohort_month;


/* --------------------------------------------------------------------------
   Q6 — Onboarding funnel
   Finding: the first stages are 100% by design (every user in this
   dataset registers/subscribes/watches something). The real leak is
   later: 72% survive to month 3, only 30% survive to month 6.
   -------------------------------------------------------------------------- */
SELECT 'Registered' AS stage, COUNT(*) AS users FROM user_summary
UNION ALL SELECT 'Started Subscription', COUNT(*) FROM user_summary
UNION ALL SELECT 'Watched First Show', COUNT(*) FROM user_summary
UNION ALL SELECT 'Watched Weekly', COUNT(*) FROM user_summary
UNION ALL SELECT 'Stayed After 3 Months', SUM(stayed_3mo) FROM user_summary
UNION ALL SELECT 'Stayed After 6 Months', SUM(stayed_6mo) FROM user_summary;


/* --------------------------------------------------------------------------
   Q7 — Household size (number of profiles) vs. tenure
   Finding: no meaningful effect — avg tenure sits flat around ~4.9
   months regardless of profile count. Useful negative result.
   -------------------------------------------------------------------------- */
SELECT
    p.profiles,
    COUNT(*)                                    AS users,
    ROUND(AVG(u.churn_month), 1)                AS avg_months_to_churn
FROM user_summary u
JOIN (SELECT user_id, MIN(number_of_profiles) AS profiles FROM users_raw GROUP BY user_id) p
    ON p.user_id = u.user_id
GROUP BY p.profiles
ORDER BY p.profiles;


/* --------------------------------------------------------------------------
   Q8 — Device type vs. churn
   Finding: churn rate is flat (99.5-100%) across Laptop / Mobile / TV —
   device is not a differentiator at this scale.
   -------------------------------------------------------------------------- */
SELECT
    device_type,
    COUNT(*)                                    AS users,
    ROUND(100.0 * AVG(ever_churned), 2)         AS churn_rate_pct
FROM user_summary
GROUP BY device_type
ORDER BY churn_rate_pct DESC;
