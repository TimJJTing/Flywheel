#!/usr/bin/env node
import fs from 'fs';
import path from 'path';

const commands = new Set([
  'python3 flywheel/resolve-spawn.py',
  'python3 "$(git rev-parse --show-toplevel)/flywheel/resolve-spawn.py" codex',
  'python3 flywheel/resolve-spawn.py antigravity',
]);
const load = path => JSON.parse(fs.readFileSync(path, 'utf8'));
const write = (path, value) => fs.writeFileSync(path, JSON.stringify(value, null, 2) + '\n');
function stable(value) {
  if (Array.isArray(value)) return '[' + value.map(stable).join(',') + ']';
  if (value && typeof value === 'object') {
    return '{' + Object.keys(value).sort().map(key => JSON.stringify(key) + ':' + stable(value[key])).join(',') + '}';
  }
  return JSON.stringify(value);
}
function deepMerge(dest, src, path = '') {
  let changed = false;
  if (dest && src && typeof dest === 'object' && typeof src === 'object' &&
      !Array.isArray(dest) && !Array.isArray(src)) {
    for (const key of Object.keys(src)) {
      const childPath = path ? `${path}.${key}` : key;
      if (!(key in dest)) { dest[key] = src[key]; changed = true; }
      else {
        const [childChanged, child] = deepMerge(dest[key], src[key], childPath);
        dest[key] = child;
        changed = changed || childChanged;
      }
    }
    return [changed, dest];
  }
  if (Array.isArray(dest) && Array.isArray(src)) {
    for (const item of src) {
      if (!dest.some(existing => stable(existing) === stable(item))) {
        dest.push(item);
        changed = true;
      }
    }
    return [changed, dest];
  }
  if (JSON.stringify(dest) !== JSON.stringify(src)) console.error(`  skip (differs): ${path}`);
  return [false, dest];
}
function cleanFlywheel(value) {
  if (Array.isArray(value)) {
    let removedAny = false;
    const result = [];
    for (const item of value) {
      if (item && typeof item === 'object' && !Array.isArray(item) && commands.has(String(item.command || ''))) {
        removedAny = true;
        continue;
      }
      const [newItem, removed] = cleanFlywheel(item);
      removedAny = removedAny || removed;
      if (removed && item && typeof item === 'object' && !Array.isArray(item) && Array.isArray(item.hooks) &&
          (!newItem || typeof newItem !== 'object' || !Array.isArray(newItem.hooks) || newItem.hooks.length === 0)) continue;
      result.push(newItem);
    }
    return [result, removedAny];
  }
  if (value && typeof value === 'object') {
    let removedAny = false;
    const result = {};
    for (const key of Object.keys(value)) {
      if (key === 'flywheel-spawn-log') { removedAny = true; continue; }
      const [child, removed] = cleanFlywheel(value[key]);
      removedAny = removedAny || removed;
      if (removed && ((Array.isArray(child) && child.length === 0) ||
          (child && typeof child === 'object' && !Array.isArray(child) && Object.keys(child).length === 0))) continue;
      result[key] = child;
    }
    return [result, removedAny];
  }
  return [value, false];
}
function effectivelyEmpty(value) {
  if (Array.isArray(value)) return value.length === 0;
  if (value && typeof value === 'object') return Object.values(value).every(effectivelyEmpty);
  return false;
}
function hasCommand(value) {
  if (Array.isArray(value)) return value.some(hasCommand);
  if (value && typeof value === 'object') return commands.has(value.command) || Object.values(value).some(hasCommand);
  return false;
}

const [operation, first, second] = process.argv.slice(2);
if (operation === 'valid') load(first);
else if (operation === 'equal') console.log(stable(load(first)) === stable(load(second)) ? 'yes' : 'no');
else if (operation === 'deep-merge') {
  const [changed, result] = deepMerge(load(second), load(first));
  if (changed) write(second, result);
  console.log(changed ? 'merged' : 'already-merged');
} else if (operation === 'unmerge') {
  const [result, removed] = cleanFlywheel(load(first));
  if (!removed) console.log('no-flywheel-entries-found');
  else if (effectivelyEmpty(result)) { fs.unlinkSync(first); console.log('removed (empty after unmerge)'); }
  else { write(first, result); console.log('unmerged'); }
} else if (operation === 'has-command') console.log(hasCommand(load(first)) ? 'yes' : 'no');
else if (operation === 'opencode-merge') {
  const mergeAgents = load(first).agent || {};
  const dest = load(second);
  if (!dest.agent) dest.agent = {};
  let changed = false;
  for (const [key, value] of Object.entries(mergeAgents)) {
    if (!(key in dest.agent)) { dest.agent[key] = value; changed = true; }
    else if (JSON.stringify(dest.agent[key]) !== JSON.stringify(value)) console.error(`  skip (differs): agent.${key}`);
  }
  if (changed) write(second, dest);
  console.log(changed ? 'merged' : 'already-merged');
} else if (operation === 'opencode-only') {
  const mergeDoc = load(first), destDoc = load(second);
  // Legacy installs had no ownership marker. Key-set equality is insufficient:
  // nested agent edits must prevent deletion too.
  console.log(stable(mergeDoc) === stable(destDoc) ? 'yes' : 'no');
} else if (operation === 'project-adapters') {
  const root = first, tiers = load(path.join(root, 'flywheel', 'config.json')).tiers || {};
  const names = {architect:'architect', strategist:'researcher', engineer:'engineer', utility:'utility', verifier:'verifier', auditor:'plan-auditor'};
  for (const [tier, name] of Object.entries(names)) {
    for (const [adapter, rel, modelPattern, levelPattern, modelKey, levelKey] of [
      ['claude-code', `.claude/agents/${name}.md`, /^model:\s*\S+/m, /^effort:\s*\S+/m, 'model', 'level'],
      ['codex', `.codex/agents/${name}.toml`, /^model\s*=\s*"[^"]*"/m, /^model_reasoning_effort\s*=\s*"[^"]*"/m, 'model', 'level'],
    ]) {
      const p = path.join(root, rel), c = (((tiers[tier]||{}).adapters||{})[adapter]||{});
      if (!fs.existsSync(p) || c[modelKey] === 'Pending verification' || c[levelKey] === 'Pending verification') continue;
      let text = fs.readFileSync(p, 'utf8');
      if (!text.includes('flywheel-managed')) continue;
      text = text.replace(modelPattern, adapter === 'codex' ? `model = "${c.model}"` : `model: ${c.model}`);
      text = text.replace(levelPattern, adapter === 'codex' ? `model_reasoning_effort = "${c.level}"` : `effort: ${c.level}`);
      fs.writeFileSync(p, text);
    }
    const p = path.join(root, 'opencode.json'), c = (((tiers[tier]||{}).adapters||{}).opencode||{});
    if (fs.existsSync(p) && c.provider && c.model && c.provider !== 'Pending verification' && c.model !== 'Pending verification') {
      const data = load(p), agent = (data.agent||{})[tier];
      if (agent && String(agent.description||'').startsWith('Flywheel ')) { agent.model = `${c.provider}/${c.model}`; write(p, data); }
    }
  }
} else throw new Error(`unknown JSON lifecycle operation: ${operation}`);
