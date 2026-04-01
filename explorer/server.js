const http = require('http');
const { execFileSync } = require('child_process');

const PORT = 4402;
const CLI = process.env.SHARDCOIN_CLI || 'shardcoin-cli';
const CLI_EXTRA = (process.env.SHARDCOIN_CLI_ARGS || '').split(' ').filter(Boolean);

function rpc(method, ...params) {
    try {
        const args = [...CLI_EXTRA, method, ...params.map(String)];
        const result = execFileSync(CLI, args, { timeout: 10000 });
        return JSON.parse(result.toString());
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

function serveIndex(res) {
    const fs = require('fs');
    const path = require('path');
    const indexPath = path.join(__dirname, 'index.html');
    if (fs.existsSync(indexPath)) {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(fs.readFileSync(indexPath));
    } else {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end('<html><body><h1>ShardCoin Explorer</h1><p>index.html not found</p></body></html>');
    }
}

const server = http.createServer((req, res) => {
    const url = new URL(req.url, `http://localhost:${PORT}`);

    if (url.pathname === '/' || url.pathname === '/index.html') {
        return serveIndex(res);
    }

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
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`ShardCoin Explorer running on http://0.0.0.0:${PORT}`);
});
