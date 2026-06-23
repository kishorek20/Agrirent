import openpyxl
from openpyxl.styles import Font, Alignment, PatternFill, Border, Side
from openpyxl.chart import BarChart, Reference
from openpyxl.utils import get_column_letter
import json
import datetime
import os
import sys

def parse_k6_json(json_path):
    """Parse the K6 JSON summary output file."""
    with open(json_path, 'r') as f:
        data = json.load(f)

    metrics = data.get('metrics', {})
    root_group = data.get('root_group', {})

    # ── Overall Summary ──────────────────────────────────────────────────
    http_reqs = metrics.get('http_reqs', {})
    http_duration = metrics.get('http_req_duration', {})
    iterations = metrics.get('iterations', {})
    vus = metrics.get('vus', {})
    data_received = metrics.get('data_received', {})
    data_sent = metrics.get('data_sent', {})
    checks = metrics.get('checks', {})

    duration_vals = http_duration.get('values', {})
    
    summary = {
        'Total Requests': int(http_reqs.get('values', {}).get('count', 0)),
        'Requests/sec (RPS)': round(http_reqs.get('values', {}).get('rate', 0), 2),
        'Avg Response Time (ms)': round(duration_vals.get('avg', 0), 2),
        'Min Response Time (ms)': round(duration_vals.get('min', 0), 2),
        'Max Response Time (ms)': round(duration_vals.get('max', 0), 2),
        'Median Response Time (ms)': round(duration_vals.get('med', 0), 2),
        'p90 Response Time (ms)': round(duration_vals.get('p(90)', 0), 2),
        'p95 Response Time (ms)': round(duration_vals.get('p(95)', 0), 2),
        'Total Iterations': int(iterations.get('values', {}).get('count', 0)),
        'Virtual Users': int(vus.get('values', {}).get('max', 0)),
        'Data Received (MB)': round(data_received.get('values', {}).get('count', 0) / (1024 * 1024), 2),
        'Data Sent (MB)': round(data_sent.get('values', {}).get('count', 0) / (1024 * 1024), 2),
        'Check Pass Rate (%)': round(checks.get('values', {}).get('rate', 0) * 100, 2) if checks else 'N/A',
    }

    # ── Per-Endpoint Breakdown ───────────────────────────────────────────
    endpoint_metrics = {}
    endpoint_prefixes = {
        'health_req_duration': 'Health Check',
        'vehicles_req_duration': 'GET /vehicles',
        'users_req_duration': 'GET /users',
        'bookings_req_duration': 'GET /bookings',
        'notifications_req_duration': 'GET /notifications',
        'payments_req_duration': 'GET /payments',
        'reviews_req_duration': 'GET /reviews',
    }

    for metric_key, display_name in endpoint_prefixes.items():
        m = metrics.get(metric_key, {})
        vals = m.get('values', {})
        if vals:
            endpoint_metrics[display_name] = {
                'Avg (ms)': round(vals.get('avg', 0), 2),
                'Min (ms)': round(vals.get('min', 0), 2),
                'Max (ms)': round(vals.get('max', 0), 2),
                'Median (ms)': round(vals.get('med', 0), 2),
                'p90 (ms)': round(vals.get('p(90)', 0), 2),
                'p95 (ms)': round(vals.get('p(95)', 0), 2),
                'Count': int(m.get('values', {}).get('count', 0)) if 'count' in vals else 'N/A',
            }

    return summary, endpoint_metrics


def generate_excel(summary, endpoint_metrics, output_path):
    """Generate a styled Excel report from K6 results."""
    wb = openpyxl.Workbook()

    # ── Colors & Styles ──────────────────────────────────────────────────
    dark_bg = PatternFill("solid", fgColor="1B1F2A")
    header_fill = PatternFill("solid", fgColor="6C63FF")  # Purple accent
    metric_fill = PatternFill("solid", fgColor="232836")
    green_fill = PatternFill("solid", fgColor="00C853")
    amber_fill = PatternFill("solid", fgColor="FFB300")
    red_fill = PatternFill("solid", fgColor="FF1744")

    white_font = Font(color="FFFFFF", size=11)
    bold_white = Font(color="FFFFFF", size=11, bold=True)
    header_font = Font(color="FFFFFF", size=12, bold=True)
    title_font = Font(color="FFFFFF", size=16, bold=True)
    subtitle_font = Font(color="B0BEC5", size=10, italic=True)
    value_font = Font(color="E0E0E0", size=11)
    big_value_font = Font(color="00E676", size=14, bold=True)

    thin_border = Border(
        left=Side(style='thin', color='37474F'),
        right=Side(style='thin', color='37474F'),
        top=Side(style='thin', color='37474F'),
        bottom=Side(style='thin', color='37474F'),
    )

    center = Alignment(horizontal="center", vertical="center")
    left = Alignment(horizontal="left", vertical="center")
    wrap = Alignment(wrap_text=True, vertical="center")

    # ══════════════════════════════════════════════════════════════════════
    # Sheet 1: Overview Dashboard
    # ══════════════════════════════════════════════════════════════════════
    ws1 = wb.active
    ws1.title = "Load Test Overview"
    ws1.sheet_properties.tabColor = "6C63FF"

    # Set dark background for all cells
    for row in range(1, 30):
        for col in range(1, 8):
            cell = ws1.cell(row=row, column=col)
            cell.fill = dark_bg

    # Title
    ws1.merge_cells('A1:G1')
    title_cell = ws1['A1']
    title_cell.value = "🚀 AgriRent — K6 Baseline Load Test Report"
    title_cell.font = title_font
    title_cell.fill = PatternFill("solid", fgColor="6C63FF")
    title_cell.alignment = center

    # Subtitle
    ws1.merge_cells('A2:G2')
    sub_cell = ws1['A2']
    sub_cell.value = f"Generated: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | 100 VUs | 1 Minute Duration | Supabase REST API"
    sub_cell.font = subtitle_font
    sub_cell.fill = dark_bg
    sub_cell.alignment = center

    # Summary KPIs
    row = 4
    ws1.merge_cells('A4:G4')
    sec_header = ws1['A4']
    sec_header.value = "📊 Key Performance Indicators"
    sec_header.font = Font(color="FFFFFF", size=13, bold=True)
    sec_header.fill = PatternFill("solid", fgColor="37474F")
    sec_header.alignment = center

    row = 5
    for key, value in summary.items():
        ws1.cell(row=row, column=2, value=key).font = bold_white
        ws1.cell(row=row, column=2).fill = metric_fill
        ws1.cell(row=row, column=2).alignment = left
        ws1.cell(row=row, column=2).border = thin_border

        val_cell = ws1.cell(row=row, column=4, value=value)
        val_cell.font = big_value_font
        val_cell.fill = metric_fill
        val_cell.alignment = center
        val_cell.border = thin_border

        # Status indicator
        status_cell = ws1.cell(row=row, column=5)
        if 'Response Time' in key and isinstance(value, (int, float)):
            if value < 500:
                status_cell.value = "✅ FAST"
                status_cell.fill = green_fill
            elif value < 1500:
                status_cell.value = "⚠️ OK"
                status_cell.fill = amber_fill
            else:
                status_cell.value = "🔴 SLOW"
                status_cell.fill = red_fill
            status_cell.font = Font(color="FFFFFF", bold=True)
            status_cell.alignment = center
        row += 1

    # Column widths
    ws1.column_dimensions['A'].width = 3
    ws1.column_dimensions['B'].width = 30
    ws1.column_dimensions['C'].width = 3
    ws1.column_dimensions['D'].width = 20
    ws1.column_dimensions['E'].width = 15
    ws1.column_dimensions['F'].width = 15
    ws1.column_dimensions['G'].width = 3

    # ══════════════════════════════════════════════════════════════════════
    # Sheet 2: Per-Endpoint Breakdown
    # ══════════════════════════════════════════════════════════════════════
    ws2 = wb.create_sheet("Endpoint Breakdown")
    ws2.sheet_properties.tabColor = "00BCD4"

    # Dark background
    for r in range(1, len(endpoint_metrics) + 10):
        for c in range(1, 10):
            ws2.cell(row=r, column=c).fill = dark_bg

    # Title
    ws2.merge_cells('A1:H1')
    t2 = ws2['A1']
    t2.value = "📡 Per-Endpoint Response Time Breakdown"
    t2.font = title_font
    t2.fill = PatternFill("solid", fgColor="00BCD4")
    t2.alignment = center

    # Headers
    ep_headers = ["Endpoint", "Avg (ms)", "Min (ms)", "Max (ms)", "Median (ms)", "p90 (ms)", "p95 (ms)", "Count"]
    for col_idx, h in enumerate(ep_headers, 1):
        cell = ws2.cell(row=3, column=col_idx, value=h)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = center
        cell.border = thin_border

    # Data rows
    r = 4
    for ep_name, vals in endpoint_metrics.items():
        ws2.cell(row=r, column=1, value=ep_name).font = bold_white
        ws2.cell(row=r, column=1).fill = metric_fill
        ws2.cell(row=r, column=1).alignment = left
        ws2.cell(row=r, column=1).border = thin_border

        col = 2
        for metric_key in ['Avg (ms)', 'Min (ms)', 'Max (ms)', 'Median (ms)', 'p90 (ms)', 'p95 (ms)', 'Count']:
            v = vals.get(metric_key, 'N/A')
            cell = ws2.cell(row=r, column=col, value=v)
            cell.font = value_font
            cell.fill = metric_fill
            cell.alignment = center
            cell.border = thin_border

            # Color code avg response time
            if metric_key == 'Avg (ms)' and isinstance(v, (int, float)):
                if v < 300:
                    cell.font = Font(color="00E676", bold=True)
                elif v < 1000:
                    cell.font = Font(color="FFB300", bold=True)
                else:
                    cell.font = Font(color="FF1744", bold=True)
            col += 1
        r += 1

    # Column widths
    ws2.column_dimensions['A'].width = 25
    for c in range(2, 9):
        ws2.column_dimensions[get_column_letter(c)].width = 15

    # ── Add a bar chart for avg response times ───────────────────────────
    if endpoint_metrics:
        chart = BarChart()
        chart.type = "col"
        chart.title = "Average Response Time by Endpoint (ms)"
        chart.y_axis.title = "ms"
        chart.x_axis.title = "Endpoint"
        chart.style = 10

        data_ref = Reference(ws2, min_col=2, min_row=3, max_row=3 + len(endpoint_metrics))
        cats_ref = Reference(ws2, min_col=1, min_row=4, max_row=3 + len(endpoint_metrics))
        chart.add_data(data_ref, titles_from_data=True)
        chart.set_categories(cats_ref)
        chart.shape = 4
        chart.width = 22
        chart.height = 12
        ws2.add_chart(chart, f"A{r + 2}")

    # ══════════════════════════════════════════════════════════════════════
    # Sheet 3: Test Configuration
    # ══════════════════════════════════════════════════════════════════════
    ws3 = wb.create_sheet("Test Configuration")
    ws3.sheet_properties.tabColor = "FF9800"

    for r in range(1, 20):
        for c in range(1, 5):
            ws3.cell(row=r, column=c).fill = dark_bg

    ws3.merge_cells('A1:D1')
    t3 = ws3['A1']
    t3.value = "⚙️ Load Test Configuration"
    t3.font = title_font
    t3.fill = PatternFill("solid", fgColor="FF9800")
    t3.alignment = center

    config_items = [
        ("Test Tool", "Grafana K6"),
        ("Test Type", "Baseline / Load Test"),
        ("Virtual Users (VUs)", "100"),
        ("Duration", "1 minute"),
        ("Target System", "AgriRent Supabase REST API"),
        ("Base URL", "https://atafeyidjdzedbktzivx.supabase.co"),
        ("Endpoints Tested", "7 (Health, Vehicles, Users, Bookings, Notifications, Payments, Reviews)"),
        ("Think Time", "300ms between iterations"),
        ("Threshold: p95", "< 2000ms"),
        ("Threshold: Error Rate", "< 10%"),
        ("Execution Date", datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")),
    ]

    row = 3
    for key, value in config_items:
        ws3.cell(row=row, column=1, value=key).font = bold_white
        ws3.cell(row=row, column=1).fill = metric_fill
        ws3.cell(row=row, column=1).border = thin_border
        ws3.cell(row=row, column=2, value=value).font = value_font
        ws3.cell(row=row, column=2).fill = metric_fill
        ws3.cell(row=row, column=2).border = thin_border
        row += 1

    ws3.column_dimensions['A'].width = 25
    ws3.column_dimensions['B'].width = 60

    # ── Save ─────────────────────────────────────────────────────────────
    os.makedirs(os.path.dirname(output_path) or '.', exist_ok=True)
    wb.save(output_path)
    print(f"[OK] K6 Load Test Excel report generated at: {output_path}")


if __name__ == "__main__":
    json_path = sys.argv[1] if len(sys.argv) > 1 else "test_reports/k6_results.json"
    output_path = sys.argv[2] if len(sys.argv) > 2 else "test_reports/K6_Load_Test_Report.xlsx"
    
    summary, endpoint_metrics = parse_k6_json(json_path)
    generate_excel(summary, endpoint_metrics, output_path)
