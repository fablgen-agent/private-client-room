#!/usr/bin/env node

import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { createServer } from 'node:http';
import { extname, resolve, sep } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const moduleDirectory = fileURLToPath(new URL('.', import.meta.url));
const defaultRoot = resolve(moduleDirectory, '../docs');

const contentTypes = new Map([
  ['.css', 'text/css; charset=utf-8'],
  ['.html', 'text/html; charset=utf-8'],
  ['.jpg', 'image/jpeg'],
  ['.js', 'text/javascript; charset=utf-8'],
  ['.json', 'application/json; charset=utf-8'],
  ['.mjs', 'text/javascript; charset=utf-8'],
  ['.png', 'image/png'],
  ['.svg', 'image/svg+xml'],
  ['.txt', 'text/plain; charset=utf-8'],
  ['.webp', 'image/webp'],
  ['.xml', 'application/xml; charset=utf-8'],
]);

const securityHeaders = {
  'Content-Security-Policy': "default-src 'self'; base-uri 'none'; connect-src 'self'; form-action 'self' https://work.enby.fish https://github.com https://t.me mailto:; frame-ancestors 'none'; img-src 'self'; object-src 'none'; script-src 'self'; style-src 'self'; upgrade-insecure-requests",
  'Cross-Origin-Opener-Policy': 'same-origin',
  'Permissions-Policy': 'camera=(), geolocation=(), microphone=(), payment=(), usb=()',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
};

function sendText(response, statusCode, body, extraHeaders = {}) {
  const payload = Buffer.from(body);
  response.writeHead(statusCode, {
    ...securityHeaders,
    'Cache-Control': 'no-store',
    'Content-Length': payload.length,
    'Content-Type': 'text/plain; charset=utf-8',
    ...extraHeaders,
  });
  response.end(payload);
}

function requestPath(rawUrl) {
  try {
    const pathname = decodeURIComponent(new URL(rawUrl, 'http://localhost').pathname);
    if (pathname.includes('\0') || pathname.split('/').includes('..')) return undefined;
    return pathname;
  } catch {
    return undefined;
  }
}

export function createStaticServer({ root = defaultRoot } = {}) {
  const publicRoot = resolve(root);

  return createServer(async (request, response) => {
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      sendText(response, 405, 'Method not allowed.\n', { Allow: 'GET, HEAD' });
      return;
    }

    const pathname = requestPath(request.url || '/');
    if (!pathname) {
      sendText(response, 400, 'Bad request.\n');
      return;
    }

    let filePath = resolve(publicRoot, `.${pathname}`);
    if (filePath !== publicRoot && !filePath.startsWith(`${publicRoot}${sep}`)) {
      sendText(response, 404, 'Not found.\n');
      return;
    }

    let fileStats;
    try {
      fileStats = await stat(filePath);
    } catch {
      sendText(response, 404, 'Not found.\n');
      return;
    }

    if (fileStats.isDirectory()) {
      if (!pathname.endsWith('/')) {
        response.writeHead(308, { ...securityHeaders, Location: `${pathname}/${new URL(request.url || '/', 'http://localhost').search}` });
        response.end();
        return;
      }
      filePath = resolve(filePath, 'index.html');
      if (!filePath.startsWith(`${publicRoot}${sep}`)) {
        sendText(response, 404, 'Not found.\n');
        return;
      }
      try {
        fileStats = await stat(filePath);
      } catch {
        sendText(response, 404, 'Not found.\n');
        return;
      }
    }

    if (!fileStats.isFile()) {
      sendText(response, 404, 'Not found.\n');
      return;
    }

    const extension = extname(filePath).toLowerCase();
    const cacheControl = extension === '.html' ? 'no-cache' : 'public, max-age=300';
    response.writeHead(200, {
      ...securityHeaders,
      'Cache-Control': cacheControl,
      'Content-Length': fileStats.size,
      'Content-Type': contentTypes.get(extension) || 'application/octet-stream',
    });
    if (request.method === 'HEAD') {
      response.end();
      return;
    }
    createReadStream(filePath).pipe(response);
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const port = Number.parseInt(process.env.PCR_PORT || '8766', 10);
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('PCR_PORT must be an integer from 1 to 65535.');
  const server = createStaticServer({ root: process.env.PCR_PUBLIC_ROOT || defaultRoot });
  server.listen(port, '127.0.0.1', () => {
    process.stdout.write(`Private Client Room origin listening on 127.0.0.1:${port}\n`);
  });
}
