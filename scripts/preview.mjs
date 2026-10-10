import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../build/web/', import.meta.url));
const types = {'.html':'text/html; charset=utf-8','.js':'text/javascript','.wasm':'application/wasm','.json':'application/json','.svg':'image/svg+xml','.png':'image/png','.jpg':'image/jpeg','.otf':'font/otf','.ttf':'font/ttf','.css':'text/css'};
try { await fs.access(path.join(root,'index.html')); }
catch { console.error('Build the preview first: flutter build web --release'); process.exit(1); }
const server = http.createServer(async (request,response) => {
  try {
    const url = new URL(request.url,'http://localhost');
    let target = path.resolve(root, '.' + decodeURIComponent(url.pathname));
    const relative = path.relative(root,target);
    if (relative.startsWith('..') || path.isAbsolute(relative)) {
      response.writeHead(403); response.end('Forbidden'); return;
    }
    if ((await fs.stat(target)).isDirectory()) target=path.join(target,'index.html');
    const body=await fs.readFile(target);
    response.writeHead(200,{'Content-Type':types[path.extname(target)]??'application/octet-stream','Cache-Control':'no-store'});
    response.end(body);
  } catch {
    response.writeHead(404); response.end('Not found');
  }
});
server.on('error',error=>{console.error(error.message);process.exit(1);});
server.listen(4173,'127.0.0.1',()=>console.log('RoleChat UI preview: http://127.0.0.1:4173'));
