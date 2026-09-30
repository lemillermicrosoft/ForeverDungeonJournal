const fs = require('fs');
const path = require('path');
const luaparse = require('luaparse');
const root = path.resolve(__dirname, '..');
const tocPath = path.join(root, 'ForeverDungeonJournal.toc');
const toc = fs.readFileSync(tocPath, 'utf8');
const errors = [];
if (!toc.includes('## Interface: 16001')) errors.push('wrong Interface');
const listed = toc.split(/\r?\n/).map(s => s.trim()).filter(s => s.endsWith('.lua'));
let combined = '';
for (const name of listed) {
  const file = path.join(root, name);
  if (!fs.existsSync(file)) { errors.push(`missing TOC file: ${name}`); continue; }
  const source = fs.readFileSync(file, 'utf8');
  combined += '\n' + source;
  try { luaparse.parse(source, { luaVersion: '5.1' }); }
  catch (error) { errors.push(`${name}: Lua 5.1 parse error: ${error.message}`); }
}
if (listed.some(name => /dev|sample/i.test(name))) errors.push('dev fixture in TOC');
for (const forbidden of ['COMBAT_LOG_EVENT_UNFILTERED', 'CombatLogGetCurrentEventInfo']) {
  if (combined.includes(forbidden)) errors.push(`forbidden combat-log API: ${forbidden}`);
}
for (const required of ['SavedVariables:', 'SavedVariablesPerCharacter:', 'RegisterDataPack', 'discoveryMode']) {
  if (!(toc + combined).includes(required)) errors.push(`missing: ${required}`);
}
if (errors.length) {
  console.error('VALIDATION FAILED\n' + errors.map(e => '- ' + e).join('\n'));
  process.exit(1);
}
console.log(`Validation passed: ${listed.length} Lua files parse as Lua 5.1; Interface 16001; no dev fixtures or combat-log APIs.`);
