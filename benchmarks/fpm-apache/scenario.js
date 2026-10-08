// Open model: a constant number of pages per second (RATE), whatever the server response time,
// so that both variants are measured under exactly the same load.
// Browsing (default): a page = 1 PHP request + 10 static assets downloaded in parallel (like a browser),
// then the visitor waits 1 second while keeping its keep-alive connections open.
// PHP_ONLY=1: RATE PHP requests per second, without assets nor think time (raw PHP throughput).
import http from 'k6/http';
import { check, group, sleep } from 'k6';

const BASE = __ENV.BASE_URL || 'http://app';
const RATE = parseInt(__ENV.RATE || '10');
const PHP_ONLY = __ENV.PHP_ONLY === '1';

const assets = [];
for (let i = 1; i <= 10; i++) {
    assets.push(['GET', `${BASE}/assets/asset${i}.css`]);
}

export const options = {
    scenarios: {
        load: {
            executor: 'constant-arrival-rate',
            rate: RATE,
            timeUnit: '1s',
            duration: __ENV.DURATION || '30s',
            preAllocatedVUs: RATE * 2,
            maxVUs: RATE * 30,
        },
    },
    summaryTrendStats: ['avg', 'p(50)', 'p(95)', 'p(99)', 'max'],
    // Required to export the page duration (sub-metric) in the summary
    thresholds: { 'group_duration{group:::page}': ['max>=0'] },
};

export default function () {
    group('page', function () {
        check(http.get(`${BASE}/index.php`), { 'page 200': (r) => r.status === 200 });
        if (!PHP_ONLY) {
            http.batch(assets).forEach((r) => check(r, { 'asset 200': (res) => res.status === 200 }));
        }
    });
    if (!PHP_ONLY) {
        sleep(1);
    }
}
