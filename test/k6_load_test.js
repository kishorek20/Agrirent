import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

// ── Custom Metrics ──────────────────────────────────────────────────────────
const vehiclesReqDuration = new Trend('vehicles_req_duration', true);
const usersReqDuration = new Trend('users_req_duration', true);
const bookingsReqDuration = new Trend('bookings_req_duration', true);
const notificationsReqDuration = new Trend('notifications_req_duration', true);
const paymentsReqDuration = new Trend('payments_req_duration', true);
const reviewsReqDuration = new Trend('reviews_req_duration', true);
const healthReqDuration = new Trend('health_req_duration', true);

const errorRate = new Rate('errors');
const successRate = new Rate('success_rate');
const totalRequests = new Counter('total_requests');

// ── Configuration ───────────────────────────────────────────────────────────
const BASE_URL = 'https://atafeyidjdzedbktzivx.supabase.co';
const ANON_KEY = 'sb_publishable_z5j2Bq8qKez-9zs2VbJJOg_eE8Q1RjJ';

const params = {
  headers: {
    'apikey': ANON_KEY,
    'Authorization': `Bearer ${ANON_KEY}`,
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  },
};

// ── K6 Options: 100 VUs for 1 minute ────────────────────────────────────────
export const options = {
  vus: 100,
  duration: '1m',
  // DNS caching to prevent local DNS resolver from being overwhelmed
  dns: {
    ttl: '60s',       // Cache DNS lookups for 60 seconds
    select: 'first',  // Use the first resolved IP
    policy: 'preferIPv4',
  },
  // Reuse TCP connections to reduce overhead
  noConnectionReuse: false,
  thresholds: {
    http_req_duration: ['p(95)<2000'],   // 95% of requests under 2s
    errors: ['rate<0.1'],                 // Error rate under 10%
  },
};

// ── Ramp up gradually to avoid DNS storm ────────────────────────────────────
// setup() runs once before all VUs start — warms the DNS cache
export function setup() {
  const warmup = http.get(`${BASE_URL}/rest/v1/vehicles?select=id&limit=1`, params);
  console.log(`Setup warmup status: ${warmup.status}`);
}

// ── Test Scenarios ──────────────────────────────────────────────────────────
export default function () {
  // 1. Health Check — GET /rest/v1/ (lightweight ping)
  const healthRes = http.get(`${BASE_URL}/rest/v1/`, { ...params, tags: { name: 'HealthCheck' } });
  healthReqDuration.add(healthRes.timings.duration);
  totalRequests.add(1);
  check(healthRes, { 'Health: status 200': (r) => r.status === 200 })
    ? successRate.add(1)
    : errorRate.add(1);

  sleep(0.1); // Small pause between requests

  // 2. Fetch All Vehicles — simulates farmer browsing
  const vehiclesRes = http.get(
    `${BASE_URL}/rest/v1/vehicles?select=*&is_available=eq.true&order=created_at.desc&limit=20`,
    { ...params, tags: { name: 'GET_Vehicles' } }
  );
  vehiclesReqDuration.add(vehiclesRes.timings.duration);
  totalRequests.add(1);
  check(vehiclesRes, { 'Vehicles: status 200': (r) => r.status === 200 })
    ? successRate.add(1)
    : errorRate.add(1);

  sleep(0.1);

  // 3. Fetch All Users — simulates admin user management
  const usersRes = http.get(
    `${BASE_URL}/rest/v1/users?select=id,name,email,role,is_active&limit=20`,
    { ...params, tags: { name: 'GET_Users' } }
  );
  usersReqDuration.add(usersRes.timings.duration);
  totalRequests.add(1);
  check(usersRes, { 'Users: status 200': (r) => r.status === 200 })
    ? successRate.add(1)
    : errorRate.add(1);

  sleep(0.1);

  // 4. Fetch Bookings — simulates owner viewing booking queue
  const bookingsRes = http.get(
    `${BASE_URL}/rest/v1/bookings?select=*&order=created_at.desc&limit=20`,
    { ...params, tags: { name: 'GET_Bookings' } }
  );
  bookingsReqDuration.add(bookingsRes.timings.duration);
  totalRequests.add(1);
  check(bookingsRes, { 'Bookings: status 200': (r) => r.status === 200 })
    ? successRate.add(1)
    : errorRate.add(1);

  sleep(0.1);

  // 5. Fetch Notifications
  const notifRes = http.get(
    `${BASE_URL}/rest/v1/notifications?select=*&order=created_at.desc&limit=20`,
    { ...params, tags: { name: 'GET_Notifications' } }
  );
  notificationsReqDuration.add(notifRes.timings.duration);
  totalRequests.add(1);
  check(notifRes, { 'Notifications: status 200': (r) => r.status === 200 })
    ? successRate.add(1)
    : errorRate.add(1);

  sleep(0.1);

  // 6. Fetch Payments — simulates earnings dashboard
  const paymentsRes = http.get(
    `${BASE_URL}/rest/v1/payments?select=*&order=created_at.desc&limit=20`,
    { ...params, tags: { name: 'GET_Payments' } }
  );
  paymentsReqDuration.add(paymentsRes.timings.duration);
  totalRequests.add(1);
  check(paymentsRes, { 'Payments: status 200': (r) => r.status === 200 })
    ? successRate.add(1)
    : errorRate.add(1);

  sleep(0.1);

  // 7. Fetch Reviews
  const reviewsRes = http.get(
    `${BASE_URL}/rest/v1/reviews?select=*&order=created_at.desc&limit=20`,
    { ...params, tags: { name: 'GET_Reviews' } }
  );
  reviewsReqDuration.add(reviewsRes.timings.duration);
  totalRequests.add(1);
  check(reviewsRes, { 'Reviews: status 200': (r) => r.status === 200 })
    ? successRate.add(1)
    : errorRate.add(1);

  // Think-time between full iterations
  sleep(0.2);
}
