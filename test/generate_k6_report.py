import json
import openpyxl
from openpyxl.styles import Font, Alignment, PatternFill, Border, Side
from openpyxl.chart import BarChart, Reference
import datetime
import os
import sys

def parse_k6_summary(json_path):
    """Parse k6 JSON summary output into structured data."""
    with open(json_path, 'r') as f:
        data = json.load(f)

    metrics = data.get('metrics', {})
    results = []

    # Map of friendly names to k6 metric keys
    metric_map = {
        'HTTP Request Duration': 'http_req_duration',
        'HTTP Request Blocked': 'http_req_blocked',
        'HTTP Request Connecting': 'http_req_connecting',
        'HTTP Request Sending': 'http_req_sending',
        'HTTP Request Waiting (TTFB)': 'http_req_waiting',
        'HTTP Request Receiving': 'http_req_receiving',
        'HTTP Request Failed': 'http_req_failed',
        'Health Check Latency': 'health_check_latency',
        'Vehicles Latency': 'vehicles_latency',
        'Users Latency': 'users_latency',
        'Bookings Latency': 'bookings_latency',
        'Payments Latency': 'payments_latency',
        'Notifications Latency': 'notifications_latency',
        'Reviews Latency': 'reviews_latency',
        'Iterations': 'iterations',
        'Virtual Users': 'vus',
        'Data Received': 'data_received',
        'Data Sent': 'data_sent',
    }

    for friendly_name, key in metric_map.items():
        m = metrics.get(key, {})
        if not m:
            continue

        metric_type = m.get('type', '')
        values = m.get('values', {})

        if metric_type == 'trend':
            results.append({
                'metric': friendly_name,
                'type': 'Trend (ms)',
                'avg': round(values.get('avg', 0), 2),
                'min': round(values.get('min', 0), 2),
                'max': round(values.get('max', 0), 2),
                'p90': round(values.get('p(90)', 0), 2),
                'p95': round(values.get('p(95)', 0), 2),
                'med': round(values.get('med', 0), 2),
                'count': values.get('count', ''),
            })
        elif metric_type == 'counter':
            results.append({
                'metric': friendly_name,
                'type': 'Counter',
                'avg': '',
                'min': '',
                'max': '',
                'p90': '',
                'p95': '',
                'med': '',
                'count': values.get('count', values.get('value', 0)),
            })
        elif metric_type == 'gauge':
            results.append({
                'metric': friendly_name,
                'type': 'Gauge',
                'avg': values.get('value', 0),
                'min': values.get('min', 0),
                'max': values.get('max', 0),
                'p90': '',
                'p95': '',
                'med': '',
                'count': '',
            })
        elif metric_type == 'rate':
            results.append({
                'metric': friendly_name,
                'type': 'Rate',
                'avg': round(values.get('rate', 0) * 100, 2),
                'min': '',
                'max': '',
                'p90': '',
                'p95': '',
                'med': '',
                'count': values.get('passes', 0),
            })

    # Extract check results
    checks = metrics.get('checks', {})
    if checks:
        vals = checks.get('values', {})
        results.append({
            'metric': 'Checks Pass Rate',
            'type': 'Rate (%)',
            'avg': round(vals.get('rate', 0) * 100, 2),
            'min': '',
            'max': '',
            'p90': '',
            'p95': '',
            'med': '',
            'count': vals.get('passes', 0),
        })

    # Extract error rate
    errors = metrics.get('errors', {})
    if errors:
        vals = errors.get('values', {})
        results.append({
            'metric': 'Custom Error Rate',
            'type': 'Rate (%)',
            'avg': round(vals.get('rate', 0) * 100, 2),
            'min': '',
            'max': '',
            'p90': '',
            'p95': '',
            'med': '',
            'count': vals.get('passes', 0),
        })

    # Compute RPS
    http_reqs = metrics.get('http_reqs', {})
    if http_reqs:
        vals = http_reqs.get('values', {})
        results.append({
            'metric': 'Requests Per Second (RPS)',
            'type': 'Rate',
            'avg': round(vals.get('rate', 0), 2),
            'min': '',
            'max': '',
            'p90': '',
            'p95': '',
            'med': '',
            'count': vals.get('count', 0),
        })

    return results

def generate_excel(results, output_path):
    """Generate a styled Excel report from parsed k6 results."""
    wb = openpyxl.Workbook()

    # ── Sheet 1: Summary ──────────────────────────────────────────────────────
    ws = wb.active
    ws.title = "Load Test Summary"

    # Title row
    ws.merge_cells('A1:I1')
    title_cell = ws['A1']
    title_cell.value = "AgriRent — k6 Baseline Load Test Report"
    title_cell.font = Font(bold=True, size=16, color="FFFFFF")
    title_cell.fill = PatternFill("solid", fgColor="1565C0")
    title_cell.alignment = Alignment(horizontal="center", vertical="center")
    ws.row_dimensions[1].height = 35

    # Subtitle
    ws.merge_cells('A2:I2')
    sub_cell = ws['A2']
    sub_cell.value = f"Generated: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  |  100 VUs  |  1 Minute Duration"
    sub_cell.font = Font(size=11, color="FFFFFF", italic=True)
    sub_cell.fill = PatternFill("solid", fgColor="1E88E5")
    sub_cell.alignment = Alignment(horizontal="center")
    ws.row_dimensions[2].height = 25

    # Headers
    headers = ["Metric", "Type", "Avg", "Min", "Max", "p(90)", "p(95)", "Median", "Count"]
    for col_idx, h in enumerate(headers, 1):
        cell = ws.cell(row=4, column=col_idx, value=h)
        cell.font = Font(bold=True, color="FFFFFF")
        cell.fill = PatternFill("solid", fgColor="0D47A1")
        cell.alignment = Alignment(horizontal="center", vertical="center")

    # Data rows
    thin_border = Border(
        left=Side(style='thin', color='BBBBBB'),
        right=Side(style='thin', color='BBBBBB'),
        top=Side(style='thin', color='BBBBBB'),
        bottom=Side(style='thin', color='BBBBBB'),
    )

    for row_idx, r in enumerate(results, 5):
        values = [r['metric'], r['type'], r['avg'], r['min'], r['max'], r['p90'], r['p95'], r['med'], r['count']]
        fill_color = "E3F2FD" if row_idx % 2 == 0 else "FFFFFF"
        for col_idx, val in enumerate(values, 1):
            cell = ws.cell(row=row_idx, column=col_idx, value=val)
            cell.alignment = Alignment(wrap_text=True, vertical="top")
            cell.fill = PatternFill("solid", fgColor=fill_color)
            cell.border = thin_border

    # Column widths
    widths = [35, 12, 12, 12, 12, 12, 12, 12, 12]
    for i, w in enumerate(widths, 1):
        ws.column_dimensions[chr(64 + i)].width = w

    # ── Sheet 2: Endpoint Latency Chart ───────────────────────────────────────
    ws2 = wb.create_sheet("Latency Chart")

    latency_metrics = [r for r in results if 'Latency' in r['metric']]
    ws2.append(["Endpoint", "Avg (ms)", "p95 (ms)", "Max (ms)"])
    for cell in ws2[1]:
        cell.font = Font(bold=True, color="FFFFFF")
        cell.fill = PatternFill("solid", fgColor="0D47A1")

    for r in latency_metrics:
        ws2.append([r['metric'].replace(' Latency', ''), r['avg'], r['p95'], r['max']])

    if latency_metrics:
        chart = BarChart()
        chart.type = "col"
        chart.title = "Endpoint Latency (ms)"
        chart.y_axis.title = "Milliseconds"
        chart.x_axis.title = "Endpoint"
        chart.style = 10
        chart.width = 28
        chart.height = 16

        cats = Reference(ws2, min_col=1, min_row=2, max_row=1 + len(latency_metrics))
        avg_data = Reference(ws2, min_col=2, min_row=1, max_row=1 + len(latency_metrics))
        p95_data = Reference(ws2, min_col=3, min_row=1, max_row=1 + len(latency_metrics))
        max_data = Reference(ws2, min_col=4, min_row=1, max_row=1 + len(latency_metrics))

        chart.add_data(avg_data, titles_from_data=True)
        chart.add_data(p95_data, titles_from_data=True)
        chart.add_data(max_data, titles_from_data=True)
        chart.set_categories(cats)
        ws2.add_chart(chart, "A" + str(3 + len(latency_metrics)))

    # ── Sheet 3: Pass/Fail Verdict ────────────────────────────────────────────
    ws3 = wb.create_sheet("Verdict")
    ws3.merge_cells('A1:C1')
    ws3['A1'].value = "Threshold Verdicts"
    ws3['A1'].font = Font(bold=True, size=14, color="FFFFFF")
    ws3['A1'].fill = PatternFill("solid", fgColor="2E7D32")
    ws3['A1'].alignment = Alignment(horizontal="center")

    ws3.append(["Threshold", "Condition", "Result"])
    for cell in ws3[2]:
        cell.font = Font(bold=True, color="FFFFFF")
        cell.fill = PatternFill("solid", fgColor="388E3C")

    # Find relevant metrics for verdicts
    http_dur = next((r for r in results if r['metric'] == 'HTTP Request Duration'), None)
    error_r = next((r for r in results if r['metric'] == 'Custom Error Rate'), None)
    rps = next((r for r in results if r['metric'] == 'Requests Per Second (RPS)'), None)

    verdicts = []
    if http_dur:
        p95_val = http_dur.get('p95', 0)
        passed = p95_val < 2000 if isinstance(p95_val, (int, float)) else True
        verdicts.append(["p(95) Response Time < 2000ms", f"Actual: {p95_val}ms", "✅ PASS" if passed else "❌ FAIL"])
    if error_r:
        err_val = error_r.get('avg', 0)
        passed = err_val < 10 if isinstance(err_val, (int, float)) else True
        verdicts.append(["Error Rate < 10%", f"Actual: {err_val}%", "✅ PASS" if passed else "❌ FAIL"])
    if rps:
        verdicts.append(["Requests Per Second", f"Actual: {rps.get('avg', 'N/A')} req/s", "ℹ️ INFO"])

    for v in verdicts:
        ws3.append(v)

    ws3.column_dimensions['A'].width = 35
    ws3.column_dimensions['B'].width = 25
    ws3.column_dimensions['C'].width = 15

    # Save
    wb.save(output_path)
    print(f"Load test Excel report generated at: {output_path}")

if __name__ == "__main__":
    json_path = sys.argv[1] if len(sys.argv) > 1 else "test_reports/k6_summary.json"
    output_path = sys.argv[2] if len(sys.argv) > 2 else "test_reports/K6_Load_Test_Report.xlsx"

    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    results = parse_k6_summary(json_path)
    generate_excel(results, output_path)
