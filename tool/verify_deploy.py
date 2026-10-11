#!/usr/bin/env python3
"""Checks a deployed PWA build serves every service-worker resource correctly.

Cloudflare Pages answers unknown paths with index.html (HTTP 200), so a file
missing from a deploy looks like a success unless the content type is checked.
This reads the RESOURCES map from the deployed flutter_service_worker.js and
fails if any non-HTML resource comes back as text/html or with a non-200
status.

Usage: python3 tool/verify_deploy.py https://staging.al-wahat-farm.pages.dev
"""

import re
import sys
import time
import urllib.error
import urllib.request


def fetch(url):
    # Cloudflare rejects Python's default User-Agent with 403.
    request = urllib.request.Request(url, headers={
        'Cache-Control': 'no-cache',
        'User-Agent': 'al-wahat-deploy-check/1.0 (+curl-compatible)',
    })
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return (response.status, response.headers.get('Content-Type', ''),
                    response.read())
    except urllib.error.HTTPError as error:
        return error.code, error.headers.get('Content-Type', ''), b''


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    base = sys.argv[1].rstrip('/')
    _, _, worker = fetch(f'{base}/flutter_service_worker.js')
    keys = re.findall(r'"([^"]+)":\s*"[0-9a-f]{32}"', worker.decode('utf-8'))
    if not keys:
        sys.exit('error: no RESOURCES found in flutter_service_worker.js')

    failures = []
    for key in keys:
        path = '/' if key == '/' else f'/{key}'
        status, content_type = None, ''
        for attempt in range(3):  # the branch alias can lag a few seconds
            status, content_type, _ = fetch(f'{base}{path}')
            html = content_type.startswith('text/html')
            expect_html = key in ('/', 'index.html') or key.endswith('.html')
            if status == 200 and html == expect_html:
                break
            time.sleep(5)
        html = content_type.startswith('text/html')
        expect_html = key in ('/', 'index.html') or key.endswith('.html')
        if status != 200 or html != expect_html:
            failures.append(f'{path}: {status} {content_type}')

    print(f'checked {len(keys)} resources at {base}')
    if failures:
        print('FAILED:')
        for failure in failures:
            print(f'  {failure}')
        sys.exit(1)
    print('all resources served with the expected content type')


if __name__ == '__main__':
    main()
