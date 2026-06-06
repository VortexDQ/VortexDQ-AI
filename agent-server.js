const http  = require('http');
const fs    = require('fs');
const path  = require('path');
const os    = require('os');
const { execSync, exec } = require('child_process');

const PORT     = 3001;
const DATA_DIR = path.join(os.homedir(), 'AppData', 'Roaming', 'VortexDQ');
const HIST_DIR = path.join(DATA_DIR, 'histories');
const DEFAULT_WS = path.join(os.homedir(), 'Desktop', 'VortexDQ Projects');
const TMP_FOLDER_FILE = 'C:\\Windows\\Temp\\vqdq_selected_folder.txt';

fs.mkdirSync(HIST_DIR, { recursive: true });
fs.mkdirSync(DEFAULT_WS, { recursive: true });

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,DELETE,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}
function send(res, data, status = 200) {
  cors(res);
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
}
function body(req) {
  return new Promise((ok, fail) => {
    let b = '';
    req.on('data', d => { b += d; if (b.length > 50e6) fail(new Error('too large')); });
    req.on('end', () => { try { ok(JSON.parse(b || '{}')); } catch(e) { fail(e); } });
  });
}

http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') { cors(res); res.writeHead(204); res.end(); return; }
  const url = req.url;

  try {

    // ── Default workspace ─────────────────────────────────────────────
    if (url === '/default-workspace') {
      fs.mkdirSync(DEFAULT_WS, { recursive: true });
      return send(res, { ok: true, path: DEFAULT_WS });
    }

    // ── Choose folder ─────────────────────────────────────────────────
    // Uses a temp .ps1 file + fixed output path to avoid any escaping issues
    if (url === '/choose-folder' && req.method === 'GET') {
      // Clean up previous result
      try { fs.unlinkSync(TMP_FOLDER_FILE); } catch (_) {}

      const ps1Path = 'C:\\Windows\\Temp\\vqdq_pick.ps1';
      const ps1Content = [
        'Add-Type -AssemblyName System.Windows.Forms',
        '[System.Windows.Forms.Application]::EnableVisualStyles()',
        '$dlg = New-Object System.Windows.Forms.FolderBrowserDialog',
        '$dlg.Description = "Choose workspace folder for VortexDQ AI"',
        '$dlg.ShowNewFolderButton = $true',
        `$dlg.SelectedPath = [System.Environment]::GetFolderPath('Desktop')`,
        '$result = $dlg.ShowDialog()',
        'if ($result -eq [System.Windows.Forms.DialogResult]::OK) {',
        `  [System.IO.File]::WriteAllText('${TMP_FOLDER_FILE}', $dlg.SelectedPath, [System.Text.Encoding]::UTF8)`,
        '}'
      ].join('\r\n');

      fs.writeFileSync(ps1Path, ps1Content, 'utf8');

      exec(
        `powershell.exe -ExecutionPolicy Bypass -STA -File "${ps1Path}"`,
        { timeout: 60000 },
        (err) => {
          // PowerShell has exited — the file is written (or wasn't if user cancelled)
          try {
            const folder = fs.readFileSync(TMP_FOLDER_FILE, 'utf8').trim();
            try { fs.unlinkSync(TMP_FOLDER_FILE); fs.unlinkSync(ps1Path); } catch (_) {}
            send(res, { ok: true, folder, cancelled: false });
          } catch {
            // File doesn't exist = user cancelled or dialog failed
            send(res, { ok: true, folder: '', cancelled: true });
          }
        }
      );
      return;
    }

    // ── Write file ────────────────────────────────────────────────────
    if (url === '/file/write' && req.method === 'POST') {
      const { filePath, content, workspace } = await body(req);
      if (!filePath) return send(res, { ok: false, error: 'No filePath' }, 400);
      const ws  = workspace || DEFAULT_WS;
      const rel = filePath.replace(/^[/\\]+/, '').replace(/\.\.[/\\]/g, '').replace(/\.\.\//g, '');
      const abs = path.join(ws, rel);
      fs.mkdirSync(path.dirname(abs), { recursive: true });
      fs.writeFileSync(abs, content ?? '', 'utf8');
      const bytes = Buffer.byteLength(content ?? '', 'utf8');
      return send(res, { ok: true, path: abs, rel, bytes });
    }

    // ── Read file ─────────────────────────────────────────────────────
    if (url === '/file/read' && req.method === 'POST') {
      const { filePath, workspace } = await body(req);
      const ws  = workspace || DEFAULT_WS;
      const rel = filePath.replace(/^[/\\]+/, '');
      const abs = path.join(ws, rel);
      const content = fs.readFileSync(abs, 'utf8');
      return send(res, { ok: true, content, path: abs });
    }

    // ── Run command ───────────────────────────────────────────────────
    if (url === '/run' && req.method === 'POST') {
      const { command, workspace } = await body(req);
      const ws = (workspace && fs.existsSync(workspace)) ? workspace : DEFAULT_WS;
      try {
        const out = execSync(command, {
          cwd: ws, timeout: 180000, encoding: 'utf8',
          shell: 'cmd.exe',
          env: { ...process.env, CI: '1', npm_config_yes: 'true', PYTHONUNBUFFERED: '1' }
        });
        return send(res, { ok: true, output: out.slice(0, 8000) });
      } catch (e) {
        const out = ((e.stdout || '') + '\n' + (e.stderr || '')).trim();
        return send(res, { ok: false, output: out.slice(0, 8000), exitCode: e.status || 1 });
      }
    }

    // ── Open folder in Explorer ───────────────────────────────────────
    if (url === '/open-folder' && req.method === 'POST') {
      const { folderPath } = await body(req);
      exec(`explorer "${folderPath || DEFAULT_WS}"`);
      return send(res, { ok: true });
    }

    // ── List workspace files ──────────────────────────────────────────
    if (url === '/file/list' && req.method === 'POST') {
      const { dirPath } = await body(req);
      const abs = path.resolve(dirPath || DEFAULT_WS);
      const walk = (dir, prefix='') => {
        let out = [];
        try {
          for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
            if (['node_modules','.git','__pycache__','.venv'].includes(e.name)) continue;
            if (e.isDirectory()) out.push(...walk(path.join(dir,e.name), prefix+e.name+'/'));
            else out.push({ name: prefix+e.name, size: fs.statSync(path.join(dir,e.name)).size });
          }
        } catch(_) {}
        return out;
      };
      return send(res, { ok: true, files: walk(abs), path: abs });
    }

    // ── History ───────────────────────────────────────────────────────
    if (url === '/history/save' && req.method === 'POST') {
      const { id, name, messages } = await body(req);
      fs.writeFileSync(path.join(HIST_DIR,`${id}.json`), JSON.stringify({id,name,messages,updated:Date.now()}), 'utf8');
      return send(res, { ok: true });
    }
    if (url === '/history/list' && req.method === 'GET') {
      const list = fs.readdirSync(HIST_DIR).filter(f=>f.endsWith('.json'))
        .map(f=>{ try{const d=JSON.parse(fs.readFileSync(path.join(HIST_DIR,f),'utf8'));return{id:d.id,name:d.name,updated:d.updated,count:d.messages?.length||0};}catch{return null;} })
        .filter(Boolean).sort((a,b)=>b.updated-a.updated);
      return send(res, { ok: true, list });
    }
    if (url.startsWith('/history/load/') && req.method === 'GET') {
      const id = decodeURIComponent(url.slice('/history/load/'.length));
      return send(res, { ok: true, ...JSON.parse(fs.readFileSync(path.join(HIST_DIR,`${id}.json`),'utf8')) });
    }
    if (url.startsWith('/history/delete/') && req.method === 'DELETE') {
      fs.unlinkSync(path.join(HIST_DIR, decodeURIComponent(url.slice('/history/delete/'.length))+'.json'));
      return send(res, { ok: true });
    }

    cors(res); res.writeHead(404); res.end('{}');

  } catch(e) {
    send(res, { ok: false, error: e.message }, 500);
  }

}).listen(PORT, '127.0.0.1', () => {
  process.stdout.write(`[VortexDQ Agent] http://127.0.0.1:${PORT}\n`);
});
