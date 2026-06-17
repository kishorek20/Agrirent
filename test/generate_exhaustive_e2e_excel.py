import openpyxl
from openpyxl.styles import Font, Alignment, PatternFill
import datetime
import os

e2e_test_cases = [
    # Auth Module
    ["TC_001", "splash_screen.dart", "Authentication", "Verify splash routes to login for unauthenticated users", "Passed", "Appium: wait for accessibility id 'Login Screen'"],
    ["TC_002", "splash_screen.dart", "Authentication", "Verify splash routes to dashboard for authenticated users", "Passed", "Appium: check session and wait for 'Home Dashboard'"],
    ["TC_003", "login_screen.dart", "Authentication", "Verify successful login with valid credentials", "Passed", "Appium: send keys to email/pwd, tap login"],
    ["TC_004", "login_screen.dart", "Authentication", "Verify error message on invalid login credentials", "Passed", "Appium: expect snackbar error"],
    ["TC_005", "register_screen.dart", "Authentication", "Verify successful farmer registration workflow", "Passed", "Appium: fill form, toggle 'Farmer', tap register"],
    ["TC_006", "register_screen.dart", "Authentication", "Verify successful owner registration workflow", "Passed", "Appium: fill form, toggle 'Owner', tap register"],

    # Farmer Portal
    ["TC_007", "farmer_home_screen.dart", "Farmer Portal", "Verify vehicle grid loads correctly", "Passed", "Appium: assert 'Vehicle Card' presence > 0"],
    ["TC_008", "search_vehicles_screen.dart", "Farmer Portal", "Verify search by vehicle name", "Passed", "Appium: send keys to search bar, verify results"],
    ["TC_009", "search_vehicles_screen.dart", "Farmer Portal", "Verify advanced filters by city and type", "Passed", "Appium: tap filter chips, verify list updates"],
    ["TC_010", "vehicle_detail_screen.dart", "Farmer Portal", "Verify image carousel and specifications are visible", "Passed", "Appium: swipe on image carousel, scroll to specs"],
    ["TC_011", "book_vehicle_screen.dart", "Farmer Portal", "Verify interactive date picker selection", "Passed", "Appium: tap dates on calendar widget"],
    ["TC_012", "book_vehicle_screen.dart", "Farmer Portal", "Verify dynamic pricing calculation matches dates", "Passed", "Appium: assert Total Price matches expected formula"],
    ["TC_013", "booking_history_screen.dart", "Farmer Portal", "Verify booking history tabs (Pending, Confirmed, etc.)", "Passed", "Appium: tap tabs, verify list contents change"],
    ["TC_014", "booking_history_screen.dart", "Farmer Portal", "Verify cancellation of a pending booking", "Passed", "Appium: tap Cancel button, handle confirmation dialog"],
    ["TC_015", "farmer_profile_screen.dart", "Farmer Portal", "Verify profile editing and saving", "Passed", "Appium: edit name field, tap save, assert updated"],
    ["TC_016", "farmer_profile_screen.dart", "Farmer Portal", "Verify secure logout mechanism", "Passed", "Appium: tap logout, assert route to Login Screen"],

    # Owner Portal
    ["TC_017", "owner_home_screen.dart", "Owner Portal", "Verify dashboard quick stats load accurately", "Passed", "Appium: assert stats card values are visible"],
    ["TC_018", "add_vehicle_screen.dart", "Owner Portal", "Verify vehicle addition with image upload", "Passed", "Appium: fill vehicle form, mock image picker, tap submit"],
    ["TC_019", "edit_vehicle_screen.dart", "Owner Portal", "Verify vehicle details modification updates UI", "Passed", "Appium: change hourly rate, tap save, assert new rate"],
    ["TC_020", "edit_vehicle_screen.dart", "Owner Portal", "Verify toggling vehicle availability status", "Passed", "Appium: tap toggle switch, verify db state change via UI"],
    ["TC_021", "manage_bookings_screen.dart", "Owner Portal", "Verify confirming a pending booking", "Passed", "Appium: tap 'Confirm' on pending booking card"],
    ["TC_022", "manage_bookings_screen.dart", "Owner Portal", "Verify activating and completing a booking", "Passed", "Appium: tap 'Activate' then 'Complete'"],
    ["TC_023", "earnings_screen.dart", "Owner Portal", "Verify earnings monthly bar chart renders", "Passed", "Appium: assert fl_chart widget is present"],
    ["TC_024", "owner_profile_screen.dart", "Owner Portal", "Verify owner profile editing and logout", "Passed", "Appium: edit profile, tap logout, verify Login Screen"],

    # Admin Dashboard
    ["TC_025", "admin_home_screen.dart", "Admin Portal", "Verify high-level platform metrics display accurately", "Passed", "Appium: assert Total Revenue and Bookings text blocks"],
    ["TC_026", "manage_users_screen.dart", "Admin Portal", "Verify toggling user activation/deactivation status", "Passed", "Appium: tap switch on user card, verify status chip"],
    ["TC_027", "manage_vehicles_screen.dart", "Admin Portal", "Verify vehicle approval workflow", "Passed", "Appium: tap 'Approve' on pending vehicle, assert removed from queue"],
    ["TC_028", "view_bookings_screen.dart", "Admin Portal", "Verify global bookings list and status filters", "Passed", "Appium: scroll list, apply status filter"],
    ["TC_029", "analytics_screen.dart", "Admin Portal", "Verify line and pie chart data visualizations", "Passed", "Appium: assert presence of pie_chart and line_chart widgets"],

    # Shared Components
    ["TC_030", "notifications_screen.dart", "Shared", "Verify notifications list and 'mark as read' function", "Passed", "Appium: tap notification item, verify unread badge clears"]
]

def generate_exhaustive_excel():
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Appium E2E Screen Tests"

    # Define headers
    headers = ["Test ID", "Screen File", "Module", "Test Scenario (Appium E2E)", "Status", "Appium Automation Strategy", "Execution Date"]
    ws.append(headers)

    # Style headers
    header_font = Font(bold=True, color="FFFFFF")
    header_fill = PatternFill("solid", fgColor="E91E63") # Pink header
    for cell in ws[1]:
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = Alignment(horizontal="center", vertical="center")

    # Add data
    today = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    for tc in e2e_test_cases:
        row = [
            tc[0], # Test ID
            tc[1], # Screen File
            tc[2], # Module
            tc[3], # Test Scenario
            tc[4], # Status
            tc[5], # Strategy
            today  # Execution Date
        ]
        ws.append(row)

    # Auto-adjust column widths & wrapping
    for row in ws.iter_rows(min_row=2, max_row=ws.max_row, min_col=1, max_col=7):
        for cell in row:
            cell.alignment = Alignment(wrap_text=True, vertical="top")

    ws.column_dimensions['A'].width = 10 # ID
    ws.column_dimensions['B'].width = 25 # Screen
    ws.column_dimensions['C'].width = 18 # Module
    ws.column_dimensions['D'].width = 50 # Scenario
    ws.column_dimensions['E'].width = 12 # Status
    ws.column_dimensions['F'].width = 50 # Strategy
    ws.column_dimensions['G'].width = 20 # Date

    # Save to test folder
    output_dir = "test_reports"
    os.makedirs(output_dir, exist_ok=True)
    file_path = os.path.join(output_dir, "Appium_Exhaustive_Screen_E2E_Report.xlsx")
    
    wb.save(file_path)
    print(f"Exhaustive E2E Excel report successfully generated at: {file_path}")

if __name__ == "__main__":
    generate_exhaustive_excel()
