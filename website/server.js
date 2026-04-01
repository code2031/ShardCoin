const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 4401;
const DOWNLOADS_DIR = path.join(__dirname, 'downloads');

// Ensure downloads directory exists
if (!fs.existsSync(DOWNLOADS_DIR)) fs.mkdirSync(DOWNLOADS_DIR);

const MIME_TYPES = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.png': 'image/png',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.json': 'application/json',
};

function serveFile(res, filePath, contentType) {
    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404);
            res.end('Not found');
            return;
        }
        res.writeHead(200, { 'Content-Type': contentType });
        res.end(data);
    });
}

function serveDownload(res, filename) {
    const filePath = path.join(DOWNLOADS_DIR, filename);
    if (!fs.existsSync(filePath)) {
        res.writeHead(404);
        res.end('File not found');
        return;
    }
    const stat = fs.statSync(filePath);
    res.writeHead(200, {
        'Content-Type': 'application/octet-stream',
        'Content-Disposition': `attachment; filename="${filename}"`,
        'Content-Length': stat.size,
    });
    fs.createReadStream(filePath).pipe(res);
}

const server = http.createServer((req, res) => {
    const url = new URL(req.url, `http://localhost:${PORT}`);

    if (url.pathname === '/' || url.pathname === '/index.html') {
        serveFile(res, path.join(__dirname, 'index.html'), 'text/html');
    } else if (url.pathname === '/logo.svg') {
        serveFile(res, path.join(__dirname, '..', 'logo.svg'), 'image/svg+xml');
    } else if (url.pathname === '/logo.png') {
        serveFile(res, path.join(__dirname, '..', 'logo.png'), 'image/png');
    } else if (url.pathname === '/whitepaper' || url.pathname === '/whitepaper.md') {
        serveFile(res, path.join(__dirname, '..', 'WHITEPAPER.md'), 'text/plain; charset=utf-8');
    } else if (url.pathname.startsWith('/download/')) {
        const filename = path.basename(url.pathname);
        serveDownload(res, filename);
    } else if (url.pathname === '/api/status') {
        // Proxy to ShardCoin RPC if available
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'ok', port: PORT }));
    } else {
        const ext = path.extname(url.pathname);
        const mime = MIME_TYPES[ext] || 'application/octet-stream';
        serveFile(res, path.join(__dirname, url.pathname), mime);
    }
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`ShardCoin website running on http://0.0.0.0:${PORT}`);
});
