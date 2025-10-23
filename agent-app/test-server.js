const http = require('http');
const fs = require('fs');
const path = require('path');

const server = http.createServer((req, res) => {
    let filePath = path.join(__dirname, 'www', req.url === '/' ? 'index.html' : req.url);
    
    const ext = path.extname(filePath);
    const mimeTypes = {
        '.html': 'text/html',
        '.css': 'text/css',
        '.js': 'application/javascript',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.ico': 'image/x-icon'
    };
    
    res.setHeader('Content-Type', mimeTypes[ext] || 'text/plain');
    
    fs.readFile(filePath, (err, data) => {
        if (err) {
            console.log('File not found:', filePath);
            res.writeHead(404);
            res.end('File not found: ' + req.url);
        } else {
            console.log('Serving:', req.url);
            res.writeHead(200);
            res.end(data);
        }
    });
});

server.listen(8080, () => {
    console.log('🚀 Knox Agent Test Server running on http://localhost:8080');
    console.log('📁 Serving files from:', path.join(__dirname, 'www'));
});
