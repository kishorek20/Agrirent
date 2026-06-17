import openpyxl
from openpyxl.styles import Font, Alignment, PatternFill
import datetime
import os

selenium_test_cases = [
    ["WEB_001", "Home Page", "Verify homepage loads on desktop view", "Passed", "Selenium: driver.get('/')"],
    ["WEB_002", "Login", "Verify web login form layout constraints", "Passed", "Selenium: check max-width"],
    ["WEB_003", "Responsive Grid", "Verify grid expands properly on web", "Passed", "Selenium: resize window and check grid items"],
    ["WEB_004", "Admin Portal", "Verify analytics charts render on canvas", "Passed", "Selenium: find fl_chart canvas elements"],
]

def generate_selenium_excel():
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Selenium E2E Web Tests"

    headers = ["Test ID", "Module", "Test Scenario (Selenium Web)", "Status", "Selenium Automation Strategy", "Execution Date"]
    ws.append(headers)

    header_font = Font(bold=True, color="FFFFFF")
    header_fill = PatternFill("solid", fgColor="00BCD4") # Cyan header
    for cell in ws[1]:
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = Alignment(horizontal="center", vertical="center")

    today = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    for tc in selenium_test_cases:
        row = tc + [today]
        ws.append(row)

    for row in ws.iter_rows(min_row=2, max_row=ws.max_row, min_col=1, max_col=6):
        for cell in row:
            cell.alignment = Alignment(wrap_text=True, vertical="top")

    ws.column_dimensions['A'].width = 12
    ws.column_dimensions['B'].width = 20
    ws.column_dimensions['C'].width = 40
    ws.column_dimensions['D'].width = 15
    ws.column_dimensions['E'].width = 50
    ws.column_dimensions['F'].width = 20

    output_dir = "test_reports"
    os.makedirs(output_dir, exist_ok=True)
    file_path = os.path.join(output_dir, "Selenium_Web_E2E_Report.xlsx")
    
    wb.save(file_path)
    print(f"Selenium Web E2E Excel report generated at: {file_path}")

if __name__ == "__main__":
    generate_selenium_excel()
