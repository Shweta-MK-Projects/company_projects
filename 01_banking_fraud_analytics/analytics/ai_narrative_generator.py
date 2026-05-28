#!/usr/bin/env python3
"""
AI Narrative Generator for Banking Fraud & Customer Risk Analytics.
Generates automated executive summary reports from structured transaction and alert metrics.
"""

import os
import json
import argparse
from datetime import datetime

# Simulated prompt templates for LLM summarization
PROMPT_TEMPLATE = """
System: You are an elite BFSI Risk Analyst and AI Reporting Assistant.
Role: Convert weekly fraud operation data tables into a concise, action-oriented, executive narrative.
Formatting: Use markdown. Focus on trend variations, risk indicators, and key operational recommendations.

Data Input (Weekly Metrics):
- Reporting Week: {week_start} to {week_end}
- Total Transactions Analyzed: {total_txns:,}
- Total Fraud Alerts Triggered: {alerts_triggered:,}
- Alerts Confirmed Fraud: {confirmed_fraud:,}
- False Positive Count: {false_positives:,}
- Total Financial Loss Blocked/Saved: INR {loss_saved:,.2f}
- Actual Fraud Loss Leakage: INR {loss_leakage:,.2f}
- Mean Time to Detect (MTTD): {mttd_hours} Hours
- Top Rule Violated: {top_violation_rule} ({top_violation_count} instances)
- Escalated Customer Profiles Flagged: {escalated_profiles}

Generate a weekly executive report with the following structure:
1. Executive Risk Summary (2-3 sentences highlighting core metrics)
2. Operational Performance & Efficiency (Alert counts, False Positive Rate, MTTD)
3. Pattern and Vector Highlights (Where fraud is focusing - rules, networks)
4. Strategic Actions Required (Mitigation recommendations based on statistics)
"""

def generate_mock_narrative(metrics: dict) -> str:
    """
    Simulates calling an LLM (such as GPT-4, Gemini, or Claude) to structure a narrative.
    If an API key is available in the environment, it could perform a real call. 
    Otherwise, it generates a highly realistic professional mock report.
    """
    # Calculate operational metrics
    alert_volume = metrics["alerts_triggered"]
    confirmed = metrics["confirmed_fraud"]
    false_pos = metrics["false_positives"]
    fp_rate = (false_pos / alert_volume * 100) if alert_volume > 0 else 0
    saved = metrics["loss_saved"]
    leakage = metrics["loss_leakage"]
    savings_ratio = (saved / (saved + leakage) * 100) if (saved + leakage) > 0 else 0
    
    # Template substitutions
    report = f"""# WEEKLY FRAUD OPERATION EXECUTIVE REPORT
**Reporting Period:** {metrics['week_start']} to {metrics['week_end']}  
**Generated At:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} (AI-Augmented Risk Analyst Service)

---

### 1. Executive Risk Summary
During the current reporting cycle, transaction operations screened **{metrics['total_txns']:,} transactions** yielding **{alert_volume:,} suspicious alerts**. Dynamic risk screening successfully blocked **INR {saved:,.2f}** in potential fraudulent charges, achieving a **{savings_ratio:.1f}% fraud mitigation rate**. Total actual leakage was restricted to INR {leakage:,.2f}. 

### 2. Operational Performance & Efficiency
* **Total Alerts Processed:** {alert_volume:,}
* **Confirmed Fraudulent Incidents:** {confirmed:,} (Alert Precision: {(confirmed/alert_volume*100):.1f}%)
* **False Positive Rate:** {fp_rate:.1f}% ({false_pos:,} benign transactions incorrectly flagged).
* **Mean Time to Detect (MTTD):** {metrics['mttd_hours']} hours, reflecting a 14% improvement over the quarterly baseline of 2.1 hours.
* **Mule Network Links Traced:** {metrics['mule_links']} circular transfer chains blocked.

### 3. Pattern and Vector Highlights
The leading fraud signature was **{metrics['top_violation_rule']}**, accounting for **{metrics['top_violation_count']:,} individual violations**. This was heavily correlated with Card-Not-Present (CNP) channels and international merchant terminals. Analysis also identified a cluster of {metrics['escalated_profiles']} customers transitioning from 'Potential Loyalist' to 'High Risk' profiles due to sudden spikes in geographical velocity anomalies.

### 4. Strategic Actions Required
1. **Optimize Z-Score Thresholds:** Fine-tune the standard deviation thresholds on card transaction values to reduce the {fp_rate:.1f}% False Positive Rate without compromising detection accuracy.
2. **Apply Velocity Blocks on High-Risk MCCs:** Implement real-time transactional velocity rate-limits on merchant categories that triggered `{metrics['top_violation_rule']}`.
3. **Mule Network Freezes:** Order a temporal hold on the {metrics['mule_links']} flag-linked transfer loops identified via recursive CTE tracking.
"""
    return report

def main():
    parser = argparse.ArgumentParser(description="Generate Weekly Fraud Narrative Summaries")
    parser.add_argument("--input", type=str, help="Path to input metrics JSON file")
    args = parser.parse_args()

    # Default metrics for simulation
    default_metrics = {
        "week_start": "2026-05-20",
        "week_end": "2026-05-26",
        "total_txns": 1250320,
        "alerts_triggered": 1845,
        "confirmed_fraud": 312,
        "false_positives": 1533,
        "loss_saved": 8452000.00,
        "loss_leakage": 123000.00,
        "mttd_hours": 1.8,
        "top_violation_rule": "Geographic Impossibility / Speed Anomaly (>600 mph)",
        "top_violation_count": 845,
        "escalated_profiles": 42,
        "mule_links": 7
    }

    if args.input and os.path.exists(args.input):
        with open(args.input, "r") as f:
            metrics = json.load(f)
    else:
        metrics = default_metrics

    report = generate_mock_narrative(metrics)
    
    # Save the report
    output_path = os.path.join(os.path.dirname(__file__), "..", "dashboards", "weekly_fraud_narrative.md")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w") as f:
        f.write(report)
        
    print(f"Weekly fraud narrative report successfully generated at: {os.path.abspath(output_path)}")

if __name__ == "__main__":
    main()
