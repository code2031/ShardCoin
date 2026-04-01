const http = require('http');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const PORT = 4402;
const WEB_DIR = path.join(__dirname, 'build', 'web');
const CLI = process.env.SHARDCOIN_CLI || 'shardcoin-cli';
const CLI_EXTRA = (process.env.SHARDCOIN_CLI_ARGS || '').split(' ').filter(Boolean);

const MIME = {
    '.html': 'text/html', '.js': 'application/javascript', '.css': 'text/css',
    '.json': 'application/json', '.wasm': 'application/wasm',
    '.png': 'image/png', '.svg': 'image/svg+xml', '.ico': 'image/x-icon',
    '.ttf': 'font/ttf', '.otf': 'font/otf', '.woff2': 'font/woff2',
};

function rpc(method, ...params) {
    try {
        const args = [...CLI_EXTRA, method, ...params.map(String)];
        return JSON.parse(execFileSync(CLI, args, { timeout: 10000 }).toString());
    } catch (e) {
        try { return JSON.parse(e.stdout?.toString() || '{}'); } catch { return null; }
    }
}

function rpcRaw(method, ...params) {
    try {
        const args = [...CLI_EXTRA, method, ...params.map(String)];
        return execFileSync(CLI, args, { timeout: 10000 }).toString().trim();
    } catch { return null; }
}

const server = http.createServer((req, res) => {
    const url = new URL(req.url, `http://localhost:${PORT}`);

    // CORS for Flutter app on port 4401
    res.setHeader('Access-Control-Allow-Origin', '*');

    // API routes
    if (url.pathname.startsWith('/api/')) {
        res.setHeader('Content-Type', 'application/json');

        if (url.pathname === '/api/info') {
            const info = rpc('getblockchaininfo') || {};
            const ai = rpc('getaiinfo');
            if (ai) info.ai = ai;
            res.end(JSON.stringify(info));
        } else if (url.pathname === '/api/blocks') {
            const info = rpc('getblockchaininfo');
            if (!info) { res.end('[]'); return; }
            const blocks = [];
            let height = info.blocks;
            for (let i = 0; i < 20 && height >= 0; i++, height--) {
                const hash = rpcRaw('getblockhash', height);
                if (!hash) break;
                const block = rpc('getblock', hash);
                if (!block) break;
                const aiProof = rpc('getaiproof', hash);
                blocks.push({
                    height: block.height, hash: block.hash, time: block.time,
                    tx: block.nTx || block.tx?.length || 0,
                    ai: aiProof?.has_proof || false,
                });
            }
            res.end(JSON.stringify(blocks));
        } else if (url.pathname.startsWith('/api/block/')) {
            const hash = url.pathname.split('/')[3];
            if (!/^[a-f0-9]{64}$/.test(hash)) { res.writeHead(400); res.end('{"error":"invalid hash"}'); return; }
            const block = rpc('getblock', hash, 1);
            if (block) {
                const aiProof = rpc('getaiproof', hash);
                if (aiProof?.has_proof) block.ai_proof = aiProof;
            }
            res.end(JSON.stringify(block || { error: 'Block not found' }));
        } else if (url.pathname.startsWith('/api/blockhash/')) {
            const height = parseInt(url.pathname.split('/')[3]);
            if (isNaN(height) || height < 0) { res.writeHead(400); res.end('{"error":"invalid height"}'); return; }
            const hash = rpcRaw('getblockhash', height);
            res.end(JSON.stringify(hash ? { hash } : { error: 'Not found' }));
        } else if (url.pathname.startsWith('/api/tx/')) {
            const txid = url.pathname.split('/')[3];
            if (!/^[a-f0-9]{64}$/.test(txid)) { res.writeHead(400); res.end('{"error":"invalid txid"}'); return; }
            const tx = rpc('getrawtransaction', txid, 1);
            res.end(JSON.stringify(tx || { error: 'Transaction not found' }));
        } else {
            res.writeHead(404);
            res.end(JSON.stringify({ error: 'Not found' }));
        }
        return;
    }

    // Serve Flutter web build
    let filePath = path.join(WEB_DIR, url.pathname === '/' ? 'index.html' : url.pathname);
    if (!fs.existsSync(filePath)) filePath = path.join(WEB_DIR, 'index.html');

    const ext = path.extname(filePath);
    fs.readFile(filePath, (err, data) => {
        if (err) { res.writeHead(404); res.end('Not found'); return; }
        res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
        res.end(data);
    });
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`ShardCoin Explorer on http://0.0.0.0:${PORT}`);
});
