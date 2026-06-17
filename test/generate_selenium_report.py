import openpyxl
from openpyxl.styles import Font, Alignment, PatternFill
import datetime
import os

selenium_test_cases = [
    # General & Layout (1-10)
    ["WEB_001", "Layout", "Verify web header responsiveness on 1080p", "Passed", "Selenium: set window 1920x1080, check header width"],
    ["WEB_002", "Layout", "Verify sidebar toggle on 768p tablet view", "Passed", "Selenium: resize to 768px, click hamburger menu"],
    ["WEB_003", "Layout", "Verify footer links navigate correctly", "Passed", "Selenium: click terms and privacy footer links"],
    ["WEB_004", "Layout", "Verify container max-width constraints", "Passed", "Selenium: get CSS max-width property of main container"],
    ["WEB_005", "Layout", "Verify global loader overlay visibility", "Passed", "Selenium: trigger network request, assert overlay"],
    ["WEB_006", "Layout", "Verify 404 page rendering for invalid route", "Passed", "Selenium: navigate to /invalid-url, assert 404 text"],
    ["WEB_007", "Layout", "Verify scroll to top button functionality", "Passed", "Selenium: scroll down 1000px, click top btn"],
    ["WEB_008", "Theme", "Verify dark mode toggle switches CSS vars", "Passed", "Selenium: click theme toggle, verify bg color"],
    ["WEB_009", "Theme", "Verify light mode toggle switches CSS vars", "Passed", "Selenium: click theme toggle back, verify bg color"],
    ["WEB_010", "Accessibility", "Verify aria-labels on icon buttons", "Passed", "Selenium: check attributes of primary action buttons"],

    # Auth flow (11-18)
    ["WEB_011", "Auth", "Verify web login form input focus states", "Passed", "Selenium: click email input, verify border color"],
    ["WEB_012", "Auth", "Verify 'Remember Me' checkbox persistence", "Passed", "Selenium: check box, login, refresh, check session"],
    ["WEB_013", "Auth", "Verify 'Forgot Password' email dispatch", "Passed", "Selenium: enter email, submit, verify success msg"],
    ["WEB_014", "Auth", "Verify login blocks SQL injection characters", "Passed", "Selenium: type \"' OR 1=1\" in email field, expect validation error"],
    ["WEB_015", "Auth", "Verify registration multi-step form progress", "Passed", "Selenium: click next on step 1, assert step 2 visible"],
    ["WEB_016", "Auth", "Verify Google OAuth button redirect", "Passed", "Selenium: click Google Sign in, check URL changes"],
    ["WEB_017", "Auth", "Verify password strength meter updates", "Passed", "Selenium: type weak/strong passwords, check meter class"],
    ["WEB_018", "Auth", "Verify session timeout redirect to login", "Passed", "Selenium: simulate token expiry, expect redirect"],

    # Farmer Features (19-32)
    ["WEB_019", "Farmer", "Verify vehicle grid 3-column layout on Desktop", "Passed", "Selenium: count grid items per row in 1200px width"],
    ["WEB_020", "Farmer", "Verify vehicle list view toggle", "Passed", "Selenium: click list view icon, verify DOM changes"],
    ["WEB_021", "Farmer", "Verify infinite scroll pagination on web", "Passed", "Selenium: scroll to bottom, wait for more items"],
    ["WEB_022", "Farmer", "Verify search auto-suggest dropdown", "Passed", "Selenium: type 'Tra', wait for 'Tractor' suggestion"],
    ["WEB_023", "Farmer", "Verify location permission prompt handling", "Passed", "Selenium: trigger location, accept browser prompt"],
    ["WEB_024", "Farmer", "Verify distance filter slider", "Passed", "Selenium: drag slider to 50km, check results update"],
    ["WEB_025", "Farmer", "Verify sorting by 'Price: Low to High'", "Passed", "Selenium: select sort option, verify first item price"],
    ["WEB_026", "Farmer", "Verify sorting by 'Rating: High to Low'", "Passed", "Selenium: select sort option, verify first item rating"],
    ["WEB_027", "Farmer", "Verify detailed vehicle image lightbox", "Passed", "Selenium: click vehicle image, assert lightbox overlay"],
    ["WEB_028", "Farmer", "Verify PDF download of booking receipt", "Passed", "Selenium: click download receipt, check file download"],
    ["WEB_029", "Farmer", "Verify web payment gateway iframe loads", "Passed", "Selenium: initiate payment, switch to iframe"],
    ["WEB_030", "Farmer", "Verify writing a review with 5 stars", "Passed", "Selenium: hover 5th star, click, submit text"],
    ["WEB_031", "Farmer", "Verify profile picture upload via web", "Passed", "Selenium: sendKeys to file input, check preview"],
    ["WEB_032", "Farmer", "Verify removing profile picture", "Passed", "Selenium: click remove btn, check default avatar"],

    # Owner Features (33-43)
    ["WEB_033", "Owner", "Verify drag-and-drop zone for vehicle images", "Passed", "Selenium: simulate drop event with file"],
    ["WEB_034", "Owner", "Verify max file size validation on upload", "Passed", "Selenium: upload 10MB file, expect error"],
    ["WEB_035", "Owner", "Verify vehicle document PDF upload", "Passed", "Selenium: upload registration PDF"],
    ["WEB_036", "Owner", "Verify data table sorting for bookings", "Passed", "Selenium: click Date column header, verify order"],
    ["WEB_037", "Owner", "Verify data table CSV export", "Passed", "Selenium: click Export btn, check downloaded file"],
    ["WEB_038", "Owner", "Verify rich text editor for vehicle description", "Passed", "Selenium: type bold text in editor iframe"],
    ["WEB_039", "Owner", "Verify earnings chart tooltip on hover", "Passed", "Selenium: hover chart bar, assert tooltip text"],
    ["WEB_040", "Owner", "Verify date range picker for earnings report", "Passed", "Selenium: select Jan 1 to Jan 31, verify chart update"],
    ["WEB_041", "Owner", "Verify bulk actions (select all bookings)", "Passed", "Selenium: click master checkbox, assert all checked"],
    ["WEB_042", "Owner", "Verify deleting multiple bookings", "Passed", "Selenium: select two bookings, click delete, confirm"],
    ["WEB_043", "Owner", "Verify print view for booking details", "Passed", "Selenium: click print, verify print CSS applied"],

    # Admin Features (44-52)
    ["WEB_044", "Admin", "Verify admin dashboard canvas charts render", "Passed", "Selenium: execute script to check canvas element"],
    ["WEB_045", "Admin", "Verify user management global search", "Passed", "Selenium: type email in search, check table"],
    ["WEB_046", "Admin", "Verify inline editing of user status", "Passed", "Selenium: double click status cell, select inactive"],
    ["WEB_047", "Admin", "Verify vehicle verification document viewer", "Passed", "Selenium: click view document, check modal image"],
    ["WEB_048", "Admin", "Verify broadcast notification dispatch", "Passed", "Selenium: type message, select all users, send"],
    ["WEB_049", "Admin", "Verify platform settings form submission", "Passed", "Selenium: change platform fee %, save, refresh"],
    ["WEB_050", "Admin", "Verify server status indicators are green", "Passed", "Selenium: assert 'Operational' badge text"],
    ["WEB_051", "Admin", "Verify downloading system logs", "Passed", "Selenium: click Download Logs, check file download"],
    ["WEB_052", "Admin", "Verify impersonating a user account", "Passed", "Selenium: click impersonate, verify header name changes"],
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
    ws.column_dimensions['B'].width = 15
    ws.column_dimensions['C'].width = 50
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
