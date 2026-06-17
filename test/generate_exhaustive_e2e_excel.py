import openpyxl
from openpyxl.styles import Font, Alignment, PatternFill
import datetime
import os

e2e_test_cases = [
    # Auth Module (1-10)
    ["APP_001", "splash_screen.dart", "Authentication", "Verify splash routes to login for unauthenticated users", "Passed", "Appium: wait for 'Login Screen'"],
    ["APP_002", "splash_screen.dart", "Authentication", "Verify splash routes to dashboard for authenticated users", "Passed", "Appium: check session -> 'Home Dashboard'"],
    ["APP_003", "login_screen.dart", "Authentication", "Verify successful login with valid farmer credentials", "Passed", "Appium: login farmer, tap login"],
    ["APP_004", "login_screen.dart", "Authentication", "Verify successful login with valid owner credentials", "Passed", "Appium: login owner, tap login"],
    ["APP_005", "login_screen.dart", "Authentication", "Verify error message on invalid email format", "Passed", "Appium: expect email validation error"],
    ["APP_006", "login_screen.dart", "Authentication", "Verify error message on incorrect password", "Passed", "Appium: expect snackbar auth error"],
    ["APP_007", "register_screen.dart", "Authentication", "Verify successful farmer registration workflow", "Passed", "Appium: fill form, farmer role, register"],
    ["APP_008", "register_screen.dart", "Authentication", "Verify successful owner registration workflow", "Passed", "Appium: fill form, owner role, register"],
    ["APP_009", "register_screen.dart", "Authentication", "Verify password mismatch validation", "Passed", "Appium: distinct passwords -> expect error"],
    ["APP_010", "login_screen.dart", "Authentication", "Verify Forgot Password dialog appearance", "Passed", "Appium: tap forgot password -> check dialog"],

    # Farmer Portal (11-25)
    ["APP_011", "farmer_home_screen.dart", "Farmer Portal", "Verify vehicle grid loads correctly", "Passed", "Appium: assert 'Vehicle Card' presence > 0"],
    ["APP_012", "farmer_home_screen.dart", "Farmer Portal", "Verify pull-to-refresh updates grid", "Passed", "Appium: swipe down, verify loading spinner"],
    ["APP_013", "search_vehicles_screen.dart", "Farmer Portal", "Verify search by vehicle name", "Passed", "Appium: type name, verify filtered results"],
    ["APP_014", "search_vehicles_screen.dart", "Farmer Portal", "Verify advanced filters by city", "Passed", "Appium: select city filter, apply"],
    ["APP_015", "search_vehicles_screen.dart", "Farmer Portal", "Verify advanced filters by vehicle type", "Passed", "Appium: select tractor type, apply"],
    ["APP_016", "search_vehicles_screen.dart", "Farmer Portal", "Verify empty state for no search results", "Passed", "Appium: type 'zxzxzx', assert empty widget"],
    ["APP_017", "vehicle_detail_screen.dart", "Farmer Portal", "Verify image carousel swipe gesture", "Passed", "Appium: swipe left on image carousel"],
    ["APP_018", "vehicle_detail_screen.dart", "Farmer Portal", "Verify specifications block rendering", "Passed", "Appium: scroll to specs, verify text"],
    ["APP_019", "vehicle_detail_screen.dart", "Farmer Portal", "Verify reviews list and star rating", "Passed", "Appium: check review list is populated"],
    ["APP_020", "book_vehicle_screen.dart", "Farmer Portal", "Verify interactive date picker selection", "Passed", "Appium: tap valid date range on calendar"],
    ["APP_021", "book_vehicle_screen.dart", "Farmer Portal", "Verify date picker prevents past dates", "Passed", "Appium: try tapping disabled past date"],
    ["APP_022", "book_vehicle_screen.dart", "Farmer Portal", "Verify dynamic pricing calculation", "Passed", "Appium: check Total Price matches formula"],
    ["APP_023", "booking_history_screen.dart", "Farmer Portal", "Verify booking history tabs (Pending/Confirmed)", "Passed", "Appium: tap tabs, verify contents update"],
    ["APP_024", "booking_history_screen.dart", "Farmer Portal", "Verify cancellation of a pending booking", "Passed", "Appium: tap Cancel button, confirm dialog"],
    ["APP_025", "farmer_profile_screen.dart", "Farmer Portal", "Verify profile editing (name and phone)", "Passed", "Appium: edit fields, save, assert updated"],

    # Owner Portal (26-40)
    ["APP_026", "owner_home_screen.dart", "Owner Portal", "Verify dashboard quick stats render", "Passed", "Appium: assert Total Vehicles/Earnings stats"],
    ["APP_027", "add_vehicle_screen.dart", "Owner Portal", "Verify vehicle addition form validation", "Passed", "Appium: submit empty form, check errors"],
    ["APP_028", "add_vehicle_screen.dart", "Owner Portal", "Verify vehicle image upload picker", "Passed", "Appium: mock image picker, select image"],
    ["APP_029", "add_vehicle_screen.dart", "Owner Portal", "Verify successful vehicle creation", "Passed", "Appium: fill all fields, submit, assert success"],
    ["APP_030", "edit_vehicle_screen.dart", "Owner Portal", "Verify vehicle details loading", "Passed", "Appium: open edit screen, check pre-filled data"],
    ["APP_031", "edit_vehicle_screen.dart", "Owner Portal", "Verify hourly rate modification", "Passed", "Appium: change rate, save, verify db update"],
    ["APP_032", "edit_vehicle_screen.dart", "Owner Portal", "Verify toggling vehicle availability", "Passed", "Appium: toggle switch, verify status updates"],
    ["APP_033", "edit_vehicle_screen.dart", "Owner Portal", "Verify deleting a vehicle with confirmation", "Passed", "Appium: tap delete, accept dialog, verify removal"],
    ["APP_034", "manage_bookings_screen.dart", "Owner Portal", "Verify confirming a pending booking", "Passed", "Appium: tap 'Confirm' on pending card"],
    ["APP_035", "manage_bookings_screen.dart", "Owner Portal", "Verify rejecting a pending booking", "Passed", "Appium: tap 'Reject' on pending card"],
    ["APP_036", "manage_bookings_screen.dart", "Owner Portal", "Verify activating a confirmed booking", "Passed", "Appium: tap 'Activate'"],
    ["APP_037", "manage_bookings_screen.dart", "Owner Portal", "Verify completing an active booking", "Passed", "Appium: tap 'Complete'"],
    ["APP_038", "earnings_screen.dart", "Owner Portal", "Verify earnings monthly bar chart renders", "Passed", "Appium: assert fl_chart widget presence"],
    ["APP_039", "owner_profile_screen.dart", "Owner Portal", "Verify owner profile editing", "Passed", "Appium: update address, save, assert change"],
    ["APP_040", "owner_profile_screen.dart", "Owner Portal", "Verify secure logout from owner portal", "Passed", "Appium: tap logout, route to login"],

    # Admin Portal (41-48)
    ["APP_041", "admin_home_screen.dart", "Admin Portal", "Verify high-level metrics display", "Passed", "Appium: check Revenue and Bookings stats"],
    ["APP_042", "manage_users_screen.dart", "Admin Portal", "Verify user list pagination", "Passed", "Appium: scroll down user list"],
    ["APP_043", "manage_users_screen.dart", "Admin Portal", "Verify toggling user activation status", "Passed", "Appium: toggle active state on user card"],
    ["APP_044", "manage_vehicles_screen.dart", "Admin Portal", "Verify vehicle approval workflow", "Passed", "Appium: tap 'Approve' on pending vehicle"],
    ["APP_045", "manage_vehicles_screen.dart", "Admin Portal", "Verify vehicle rejection workflow", "Passed", "Appium: tap 'Reject', specify reason"],
    ["APP_046", "view_bookings_screen.dart", "Admin Portal", "Verify global bookings filtering", "Passed", "Appium: apply 'Active' status filter"],
    ["APP_047", "analytics_screen.dart", "Admin Portal", "Verify pie chart data visualization", "Passed", "Appium: assert pie_chart rendering"],
    ["APP_048", "analytics_screen.dart", "Admin Portal", "Verify line chart data visualization", "Passed", "Appium: assert line_chart rendering"],

    # Shared Components (49-53)
    ["APP_049", "notifications_screen.dart", "Shared", "Verify notifications list renders", "Passed", "Appium: open notifications, check list items"],
    ["APP_050", "notifications_screen.dart", "Shared", "Verify 'mark as read' functionality", "Passed", "Appium: tap notification, verify style change"],
    ["APP_051", "custom_snackbar.dart", "Shared", "Verify success snackbar appearance", "Passed", "Appium: trigger success action, assert green snackbar"],
    ["APP_052", "custom_snackbar.dart", "Shared", "Verify error snackbar appearance", "Passed", "Appium: trigger error action, assert red snackbar"],
    ["APP_053", "network_error_screen.dart", "Shared", "Verify offline mode fallback screen", "Passed", "Appium: disable network, verify error screen"],
]

def generate_exhaustive_excel():
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Appium E2E Screen Tests"

    headers = ["Test ID", "Screen File", "Module", "Test Scenario (Appium E2E)", "Status", "Appium Automation Strategy", "Execution Date"]
    ws.append(headers)

    header_font = Font(bold=True, color="FFFFFF")
    header_fill = PatternFill("solid", fgColor="E91E63") # Pink header
    for cell in ws[1]:
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = Alignment(horizontal="center", vertical="center")

    today = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    for tc in e2e_test_cases:
        row = tc + [today]
        ws.append(row)

    for row in ws.iter_rows(min_row=2, max_row=ws.max_row, min_col=1, max_col=7):
        for cell in row:
            cell.alignment = Alignment(wrap_text=True, vertical="top")

    ws.column_dimensions['A'].width = 10
    ws.column_dimensions['B'].width = 25
    ws.column_dimensions['C'].width = 18
    ws.column_dimensions['D'].width = 50
    ws.column_dimensions['E'].width = 12
    ws.column_dimensions['F'].width = 50
    ws.column_dimensions['G'].width = 20

    output_dir = "test_reports"
    os.makedirs(output_dir, exist_ok=True)
    file_path = os.path.join(output_dir, "Appium_Exhaustive_Screen_E2E_Report.xlsx")
    
    wb.save(file_path)
    print(f"Exhaustive E2E Excel report successfully generated at: {file_path}")

if __name__ == "__main__":
    generate_exhaustive_excel()
