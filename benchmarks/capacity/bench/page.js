// Open model: RATE visitors start a page every second, whatever the server response time.
// A page = 1 PHP request + 10 static assets downloaded in parallel (like a browser),
// then the visitor waits 1 second while keeping its keep-alive connections open.
import http from 'k6/http';
import { check, group, sleep } from 'k6';

const BASE = __ENV.BASE_URL;
const RATE = parseFloat(__ENV.RATE);
const assets = Array.from({ length: 10 }, (_, i) => ['GET', `${BASE}/assets/asset${i + 1}.css`]);

export const options = {
    scenarios: {
        load: {
            executor: 'ramping-arrival-rate',
            startRate: 1,
            timeUnit: '1m',
            preAllocatedVUs: Math.ceil(RATE * (parseFloat(__ENV.THINK || '1') + 2)) + 5,
            maxVUs: Math.ceil(RATE * (parseFloat(__ENV.THINK || '1') + 20)) + 20,
            stages: [
                { duration: __ENV.RAMP || '10s', target: Math.round(RATE * 60) },
                { duration: __ENV.DURATION || '30s', target: Math.round(RATE * 60) },
            ],
        },
    },
    insecureSkipTLSVerify: true,
    summaryTrendStats: ['avg', 'p(50)', 'p(95)', 'p(99)', 'max'],
    thresholds: {
        'group_duration{group:::page}': [`p(95)<${__ENV.P95 || 500}`, `p(99)<${__ENV.P99 || 1000}`],
        http_req_failed: ['rate<0.01'],
        dropped_iterations: ['count<1'],
    },
};

export default function () {
    group('page', function () {
        check(http.get(`${BASE}/`), { 'page 200': (r) => r.status === 200 });
        http.batch(assets).forEach((r) => check(r, { 'asset 200': (res) => res.status === 200 }));
    });
    sleep(parseFloat(__ENV.THINK || '1'));
}
