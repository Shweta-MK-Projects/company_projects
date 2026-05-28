#!/usr/bin/env python3
"""
Longitudinal HRIS Dataset Generator.
Generates CSV records for employee career histories (SCD Type 2),
daily operational metrics, and termination/attrition events.
"""

import os
import csv
import random
from datetime import datetime, timedelta

# Configuration
NUM_EMPLOYEES = 500
START_DATE = datetime(2021, 5, 27)
END_DATE = datetime(2026, 5, 27)

def generate_hr_data():
    print("Generating synthetic workforce dataset...")
    output_dir = os.path.join(os.path.dirname(__file__), "output")
    os.makedirs(output_dir, exist_ok=True)

    first_names = ["Shweta", "Anil", "Deepika", "Karthik", "Priyanka", "Sandeep", "Kavitha", "Manjunath", "Roopa", "Vijay"]
    last_names = ["Kumbari", "Kulkarni", "Patil", "Gowda", "Bhat", "Nayaka", "Shetty", "Desai", "Rao", "Joshi"]
    departments = ["Engineering", "Sales", "Customer Success", "Marketing", "HR", "Finance"]
    role_families = {
        "Engineering": ["Software Engineer", "Senior Developer", "QA Analyst", "Tech Lead"],
        "Sales": ["Account Executive", "Sales Manager", "Business Development Rep"],
        "Customer Success": ["Support Engineer", "CS Specialist", "CS Manager"],
        "Marketing": ["Content Specialist", "Marketing Manager", "SEO Executive"],
        "HR": ["HR Associate", "HR Business Partner", "Talent Acquisition Specialist"],
        "Finance": ["Financial Analyst", "Accountant", "Finance Controller"]
    }
    locations = ["Bengaluru Office", "Mumbai Office", "Hubballi Office", "Remote - India"]

    employee_history = []
    attrition_events = []
    daily_status = []

    employee_key_counter = 1
    daily_key_counter = 1

    # Keep track of active employee IDs and their status
    for emp_idx in range(1, NUM_EMPLOYEES + 1):
        emp_id = f"EMP_{emp_idx:04d}"
        
        # Determine hire date (somewhere in the 5 year span)
        hire_date = START_DATE + timedelta(days=random.randint(0, 1500))
        
        # Decide if this employee has left the company
        # ~20% of employees have left
        has_left = random.random() < 0.22
        term_date = None
        if has_left:
            # left somewhere after hire date and before end date
            days_active = random.randint(90, 800)
            term_date = hire_date + timedelta(days=days_active)
            if term_date > END_DATE:
                term_date = None
                has_left = False

        # Build career records (SCD Type 2)
        # An employee can have 1 or more career events (promotions, lateral moves)
        curr_date = hire_date
        num_changes = random.randint(1, 3) if not has_left else 1
        
        first = random.choice(first_names)
        last = random.choice(last_names)
        email = f"{first.lower()}.{last.lower()}@company.com"
        dept = random.choice(departments)
        role = random.choice(role_families[dept])
        level = "L1"
        manager = f"EMP_{random.randint(1, 50):04d}"
        loc = random.choice(locations)
        comp_pct = round(random.uniform(15.0, 95.0), 2)
        engagement = random.randint(2, 5)

        for event in range(num_changes):
            is_last = (event == num_changes - 1)
            valid_from = curr_date
            
            # calculate valid_to
            if is_last:
                valid_to = term_date if has_left else None
            else:
                curr_date = curr_date + timedelta(days=random.randint(300, 600))
                valid_to = curr_date - timedelta(days=1)
                
            # Simulate a Promotion / Change
            if event > 0:
                level = "L2" if level == "L1" else "L3"
                comp_pct = min(99.0, comp_pct + random.uniform(5, 15))
                engagement = min(5, engagement + random.choice([-1, 0, 1]))
                change_reason = "Promotion"
            else:
                change_reason = "Hire"

            employee_history.append({
                "employee_key": employee_key_counter,
                "employee_id": emp_id,
                "first_name": first,
                "last_name": last,
                "email": email,
                "department": dept,
                "role_family": role,
                "job_level": level,
                "manager_employee_id": manager,
                "location": loc,
                "compensation_band_percentile": round(comp_pct, 2),
                "engagement_score": engagement,
                "valid_from": valid_from.strftime("%Y-%m-%d"),
                "valid_to": valid_to.strftime("%Y-%m-%d") if valid_to else "",
                "is_current": (valid_to is None),
                "change_reason": change_reason
            })
            
            # Log daily snapshot logs (simulating a representative log per state)
            state_duration = ((valid_to if valid_to else END_DATE) - valid_from).days
            # Log sample daily states (representing summary snapshot milestones)
            for snapshot_day in [30, 90, 180, 360, 540]:
                if snapshot_day <= state_duration:
                    daily_status.append({
                        "snapshot_key": daily_key_counter,
                        "date_key": int((valid_from + timedelta(days=snapshot_day)).strftime("%Y%m%d")),
                        "employee_key": employee_key_counter,
                        "is_active": True,
                        "training_hours_completed": round(random.uniform(2, 24), 1),
                        "tenure_days": snapshot_day,
                        "promotion_lag_months": int(snapshot_day / 30),
                        "performance_score": random.choices([1, 2, 3, 4, 5], weights=[0.05, 0.10, 0.55, 0.20, 0.10])[0]
                    })
                    daily_key_counter += 1
            
            employee_key_counter += 1

        # Attrition Log entry
        if has_left and term_date:
            reasons = ["Compensation", "Manager relations", "Career growth", "Relocation", "Personal circumstances"]
            attrition_events.append({
                "attrition_id": len(attrition_events) + 1,
                "employee_id": emp_id,
                "termination_date": term_date.strftime("%Y-%m-%d"),
                "attrition_type": random.choices(["Voluntary", "Involuntary"], weights=[0.85, 0.15])[0],
                "primary_reason": random.choice(reasons),
                "exit_interview_satisfaction_score": random.randint(1, 5)
            })

    # Save to CSV
    with open(os.path.join(output_dir, "dim_employee_history.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=employee_history[0].keys())
        writer.writeheader()
        writer.writerows(employee_history)

    with open(os.path.join(output_dir, "fact_employee_status_daily.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=daily_status[0].keys())
        writer.writeheader()
        writer.writerows(daily_status)

    with open(os.path.join(output_dir, "employee_attrition_events.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=attrition_events[0].keys())
        writer.writeheader()
        writer.writerows(attrition_events)

    print(f"Workforce simulation completed. Created {len(employee_history)} history blocks and {len(attrition_events)} exits in {output_dir}.")

if __name__ == "__main__":
    generate_hr_data()
