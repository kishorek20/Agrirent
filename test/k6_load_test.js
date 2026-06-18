import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// ─── Custom Metrics ──────────────────────────────────────────────────────────
const errorRate = new Rate('errors');
const vehiclesLatency = new Trend('vehicles_latency');
const usersLatency = new Trend('users_latency');
const bookingsLatency = new Trend('bookings_latency');
const paymentsLatency = new Trend('payments_latency');
const notificationsLatency = new Trend('notifications_latency');
const reviewsLatency = new Trend('reviews_latency');
const healthLatency = new Trend('health_check_latency');
const totalRequests = new Counter('total_requests');

// ─── Configuration ───────────────────────────────────────────────────────────
const BASE_URL = __ENV.SUPABASE_URL || 'https://atafeyidjdzedbktzivx.supabase.co';
const ANON_KEY = __ENV.SUPABASE_ANON_KEY || 'sb_publishable_z5j2Bq8qKez-9zs2VbJJOg_eE8Q1RjJ';

const headers = {
  'apikey': ANON_KEY,
  'Authorization': `Bearer ${ANON_KEY}`,
  'Content-Type': 'application/json',
  'Prefer': 'return=representation',
};

// ─── Test Options: 100 VUs for 1 minute ──────────────────────────────────────
export const options = {
  stages: [
    { duration: '10s', target: 50 },   // Ramp up to 50 users in 10s
    { duration: '10s', target: 100 },  // Ramp up to 100 users in next 10s
    { duration: '30s', target: 100 },  // Stay at 100 users for 30s
    { duration: '10s', target: 0 },    // Ramp down to 0 in 10s
  ],
  thresholds: {
    'http_req_duration': ['p(95)<2000'],  // 95% of requests under 2s
    'errors': ['rate<0.1'],               // Error rate below 10%
  },
};

// ─── Test Scenarios ──────────────────────────────────────────────────────────
export default function () {

  // 1. Health Check (Supabase REST endpoint)
  const healthRes = http.get(`${BASE_URL}/rest/v1/`, { headers, tags: { name: 'HealthCheck' } });
  healthLatency.add(healthRes.timings.duration);
  totalRequests.add(1);
  check(healthRes, {
    'health: status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(0.1);

  // 2. GET /vehicles — Fetch all vehicles (public listing)
  const vehiclesRes = http.get(`${BASE_URL}/rest/v1/vehicles?select=*&limit=20`, { headers, tags: { name: 'GET_Vehicles' } });
  vehiclesLatency.add(vehiclesRes.timings.duration);
  totalRequests.add(1);
  check(vehiclesRes, {
    'vehicles: status is 200': (r) => r.status === 200,
    'vehicles: returns array': (r) => Array.isArray(JSON.parse(r.body)),
  }) || errorRate.add(1);

  sleep(0.1);

  // 3. GET /vehicles with filter — Search by type
  const filteredRes = http.get(`${BASE_URL}/rest/v1/vehicles?select=*&type=eq.Tractor&limit=10`, { headers, tags: { name: 'GET_Vehicles_Filtered' } });
  vehiclesLatency.add(filteredRes.timings.duration);
  totalRequests.add(1);
  check(filteredRes, {
    'vehicles filtered: status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(0.1);

  // 4. GET /vehicles with ordering — Sort by price
  const sortedRes = http.get(`${BASE_URL}/rest/v1/vehicles?select=*&order=price_per_day.asc&limit=10`, { headers, tags: { name: 'GET_Vehicles_Sorted' } });
  vehiclesLatency.add(sortedRes.timings.duration);
  totalRequests.add(1);
  check(sortedRes, {
    'vehicles sorted: status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(0.1);

  // 5. GET /users — Fetch users list
  const usersRes = http.get(`${BASE_URL}/rest/v1/users?select=id,name,role,city&limit=20`, { headers, tags: { name: 'GET_Users' } });
  usersLatency.add(usersRes.timings.duration);
  totalRequests.add(1);
  check(usersRes, {
    'users: status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(0.1);

  // 6. GET /users filtered by role
  const farmersRes = http.get(`${BASE_URL}/rest/v1/users?select=id,name&role=eq.farmer&limit=10`, { headers, tags: { name: 'GET_Users_Farmers' } });
  usersLatency.add(farmersRes.timings.duration);
  totalRequests.add(1);
  check(farmersRes, {
    'farmers: status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(0.1);

  // 7. GET /bookings — Fetch bookings
  const bookingsRes = http.get(`${BASE_URL}/rest/v1/bookings?select=*&limit=20`, { headers, tags: { name: 'GET_Bookings' } });
  bookingsLatency.add(bookingsRes.timings.duration);
  totalRequests.add(1);
  check(bookingsRes, {
    'bookings: status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(0.1);

  // 8. GET /bookings filtered by status
  const pendingRes = http.get(`${BASE_URL}/rest/v1/bookings?select=*&status=eq.pending&limit=10`, { headers, tags: { name: 'GET_Bookings_Pending' } });
  bookingsLatency.add(pendingRes.timings.duration);
  totalRequests.add(1);
  check(pendingRes, {
    'bookings pending: status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(0.1);

  // 9. GET /payments — Fetch payments
  const paymentsRes = http.get(`${BASE_URL}/rest/v1/payments?select=*&limit=20`, { headers, tags: { name: 'GET_Payments' } });
  paymentsLatency.add(paymentsRes.timings.duration);
  totalRequests.add(1);
  check(paymentsRes, {
    'payments: status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(0.1);

  // 10. GET /notifications — Fetch notifications
  const notifsRes = http.get(`${BASE_URL}/rest/v1/notifications?select=*&limit=20`, { headers, tags: { name: 'GET_Notifications' } });
  notificationsLatency.add(notifsRes.timings.duration);
  totalRequests.add(1);
  check(notifsRes, {
    'notifications: status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(0.1);

  // 11. GET /reviews — Fetch reviews
  const reviewsRes = http.get(`${BASE_URL}/rest/v1/reviews?select=*&limit=20`, { headers, tags: { name: 'GET_Reviews' } });
  reviewsLatency.add(reviewsRes.timings.duration);
  totalRequests.add(1);
  check(reviewsRes, {
    'reviews: status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(0.1);

  // 12. GET /vehicles with pagination (offset)
  const paginatedRes = http.get(`${BASE_URL}/rest/v1/vehicles?select=*&limit=5&offset=5`, { headers, tags: { name: 'GET_Vehicles_Paginated' } });
  vehiclesLatency.add(paginatedRes.timings.duration);
  totalRequests.add(1);
  check(paginatedRes, {
    'vehicles paginated: status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(0.2);
}
