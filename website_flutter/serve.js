const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 4401;
const WEB_DIR = path.join(__dirname, 'build', 'web');
const DOWNLOADS_DIR = path.join(__dirname, '..', 'website', 'downloads');

const MIME = {
    '.html': 'text/html', '.js': 'application/javascript', '.css': 'text/css',
    '.json': 'application/json', '.wasm': 'application/wasm',
    '.png': 'image/png', '.svg': 'image/svg+xml', '.ico': 'image/x-icon',
    '.ttf': 'font/ttf', '.otf': 'font/otf', '.woff': 'application/font-woff',
    '.woff2': 'font/woff2', '.map': 'application/json',
};

const server = http.createServer((req, res) => {
    const url = new URL(req.url, `http://localhost:${PORT}`);

    // API: whitepaper
    if (url.pathname === '/whitepaper' || url.pathname === '/whitepaper.md') {
        const wp = path.join(__dirname, '..', 'WHITEPAPER.md');
        if (fs.existsSync(wp)) {
            res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
            res.end(fs.readFileSync(wp));
        } else {
            res.writeHead(404); res.end('Not found');
        }
        return;
    }

    // Downloads
    if (url.pathname.startsWith('/download/')) {
        const file = path.join(DOWNLOADS_DIR, path.basename(url.pathname));
        if (fs.existsSync(file)) {
            const stat = fs.statSync(file);
            res.writeHead(200, {
                'Content-Type': 'application/octet-stream',
                'Content-Disposition': `attachment; filename="${path.basename(file)}"`,
                'Content-Length': stat.size,
            });
            fs.createReadStream(file).pipe(res);
        } else {
            res.writeHead(404); res.end('Not found');
        }
        return;
    }

    // Serve Flutter web build
    let filePath = path.join(WEB_DIR, url.pathname === '/' ? 'index.html' : url.pathname);
    if (!fs.existsSync(filePath)) filePath = path.join(WEB_DIR, 'index.html'); // SPA fallback

    const ext = path.extname(filePath);
    const contentType = MIME[ext] || 'application/octet-stream';

    fs.readFile(filePath, (err, data) => {
        if (err) { res.writeHead(404); res.end('Not found'); return; }
        res.writeHead(200, { 'Content-Type': contentType });
        res.end(data);
    });
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`ShardCoin Flutter website on http://0.0.0.0:${PORT}`);
});
