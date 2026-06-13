import pandas as pd
import os

csv1 = 'appium_e2e_test_analysis.csv'
csv2 = 'appium_e2e_overall_feedback.csv'
combined_csv = 'appium_e2e_combined.csv'
excel_file = 'appium_e2e_combined.xlsx'

# 1. Combine into a single CSV
with open(combined_csv, 'w', encoding='utf-8') as outfile:
    with open(csv1, 'r', encoding='utf-8') as infile1:
        outfile.write("--- TEST ANALYSIS ---\n")
        outfile.write(infile1.read())
        outfile.write("\n\n")
    
    with open(csv2, 'r', encoding='utf-8') as infile2:
        outfile.write("--- OVERALL FEEDBACK ---\n")
        outfile.write(infile2.read())
        
print(f"Created {combined_csv}")

# 2. Convert to Excel
# For Excel, having them on separate sheets is standard and much better.
df1 = pd.read_csv(csv1)
df2 = pd.read_csv(csv2)

with pd.ExcelWriter(excel_file, engine='openpyxl') as writer:
    df1.to_excel(writer, sheet_name='Test Analysis', index=False)
    df2.to_excel(writer, sheet_name='Overall Feedback', index=False)
    
print(f"Created {excel_file}")
