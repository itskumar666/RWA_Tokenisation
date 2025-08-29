import fs from 'fs';
import path from 'path';
const file = path.join(process.cwd(), 'asset-state.json');
function readState() {
    try {
        const raw = fs.readFileSync(file, 'utf-8');
        const json = JSON.parse(raw);
        if (typeof json.assetId === 'number')
            return json;
    }
    catch { }
    return { assetId: 0 };
}
export function nextAssetId() {
    const s = readState();
    const next = (s.assetId ?? 0) + 1;
    try {
        fs.writeFileSync(file, JSON.stringify({ assetId: next }, null, 2));
    }
    catch {
        // ignore write errors on read-only envs; counter will reset on restart
    }
    return next;
}
