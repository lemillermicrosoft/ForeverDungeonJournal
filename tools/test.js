const fs = require('fs');
const path = require('path');
const assert = require('assert');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const root = path.resolve(__dirname, '..');
let assertions = 0;
function ok(value, message) { assertions++; assert.ok(value, message); }
function luaQuote(source) { return source.replace(/\\/g, '\\\\').replace(/\]/g, '\\]'); }
function runLua(source, label) {
  const L = lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
  const status = lauxlib.luaL_dostring(L, to_luastring(source));
  if (status !== lua.LUA_OK) throw new Error(`${label}: ${to_jsstring(lua.lua_tostring(L, -1))}`);
}

const registry = fs.readFileSync(path.join(root, 'DataRegistry.lua'), 'utf8');
runLua(`
local FDJ = { callbacks = {}, fired = 0 }
function FDJ:Fire() self.fired = self.fired + 1 end
function FDJ:Reveal() self.reveals = (self.reveals or 0) + 1 end
function FDJ:GetMarkerProgress() self.progress = self.progress or {}; return self.progress end
function time() return 123456 end
local function module(...) ${registry} end
module("ForeverDungeonJournal", FDJ)
FDJ:InitializeRegistry()
local valid = {
 id="test.pack", name="Test", version="1", build="16001", license="CC0", verification="verified",
 sources={{title="Fixture",kind="test",checked="2026-09-30",url="https://example.invalid"}},
 dungeons={{id="one",name="One",mapID=1,markers={{id="boss",type="boss",label="Boss",encounterID=42,verification="verified"}}}}
}
FDJ:RegisterDataPack(valid)
assert(FDJ.packs["test.pack"] == valid)
assert(FDJ.markerIndex.encounter[42][1].marker.label == "Boss")
assert(FDJ:GetDiagnostics().dungeons == 1 and FDJ:GetDiagnostics().markers == 1)
FDJ:RegisterDataPack({
 id="test.pack.two", name="Test Two", version="1", build="16001", license="CC0", verification="verified",
 sources={{title="Fixture",kind="test",checked="2026-09-30"}},
 dungeons={{id="two",name="Two",markers={{id="boss-two",type="boss",label="Boss Two",encounterID=42}}}}
})
FDJ:Observe("BOSS_KILL", 42)
assert(FDJ.reveals == 2 and FDJ.progress.firstKill == 123456)
local before = FDJ:GetDiagnostics()
local malformed = {
 id="bad",name="Bad",version="1",build="16001",license="none",verification="verified",
 sources={{title="Fixture",kind="test",checked="2026-09-30"}},
 dungeons={{id="x",name="X",markers={{id="dup",type="boss",label="A",encounterID=9},{id="dup",type="boss",label="B"}}}}
}
local accepted = pcall(FDJ.RegisterDataPack, FDJ, malformed)
assert(not accepted)
local after = FDJ:GetDiagnostics()
assert(FDJ.packs.bad == nil and FDJ.markerIndex.encounter[9] == nil)
assert(after.packs == before.packs and after.errors == before.errors + 1)
local missingProvenance = {id="no-source",name="No source",version="1",build="x",license="x",verification="verified",sources={},dungeons={}}
assert(not pcall(FDJ.RegisterDataPack, FDJ, missingProvenance))
local badMap = {id="bad-map",name="Bad map",version="1",build="x",license="x",verification="verified",sources={{title="F",kind="test",checked="2026-09-30"}},dungeons={{id="d",name="D",map="bad",markers={}}}}
assert(not pcall(FDJ.RegisterDataPack, FDJ, badMap))
local sparse = {id="sparse",name="Sparse",version="1",build="x",license="x",verification="verified",sources={[2]={title="F",kind="test",checked="2026-09-30"}},dungeons={}}
assert(not pcall(FDJ.RegisterDataPack, FDJ, sparse))
`, 'registry/data/provenance/malformed-pack tests');
ok(true, 'registry Lua tests');

const database = fs.readFileSync(path.join(root, 'Database.lua'), 'utf8');
runLua(`
local FDJ = {}
ForeverDungeonJournalDB = {schema=1,settings={appearance="bogus",progressScope="bogus",discoveryMode="bad",show="bad"},progress="bad"}
ForeverDungeonJournalCharDB = {progress="bad",annotations="bad"}
local function module(...) ${database} end
module("ForeverDungeonJournal", FDJ)
FDJ:InitializeDatabase()
assert(ForeverDungeonJournalDB.schema == 3 and ForeverDungeonJournalDB.migrations[3])
assert(ForeverDungeonJournalDB.settings.appearance == "blizzard")
assert(ForeverDungeonJournalDB.settings.progressScope == "character")
assert(ForeverDungeonJournalDB.settings.discoveryMode == true)
assert(type(ForeverDungeonJournalDB.progress) == "table" and type(ForeverDungeonJournalCharDB.annotations) == "table")
assert(ForeverDungeonJournalDB.settings.show.boss == true)
`, 'migration tests');
ok(true, 'migration Lua tests');

const nativeData = fs.readFileSync(path.join(root, 'NativeData.lua'), 'utf8');
runLua(`
unpack = unpack or table.unpack
local FDJ = {}
function FDJ:DetectIntegrations() self.integrations = {} end
function FDJ:RegisterDataPack(pack) self.captured = pack end
local tier = 1
function EJ_GetCurrentTier() return tier end
function EJ_GetNumTiers() return 2 end
function EJ_SelectTier(value) tier = value end
function EJ_GetNumInstances() return 1 end
function EJ_GetInstanceByIndex(index)
 if tier == 1 then return 101, "Dungeon One", "Description", 9001, nil, nil, nil, 501 end
 return 102, "Dungeon Two", "Description", 9002, nil, nil, nil, 502
end
function EJ_GetEncounterInfoByIndex(index, instanceID)
 if index > 1 then return nil end
 return "Boss " .. instanceID, "Observed", instanceID + 1000, nil, nil, nil, nil, 600
end
function GetBuildInfo() return "1.60.1", "70124" end
function date() return "2026-09-30" end
local function module(...) ${nativeData} end
module("ForeverDungeonJournal", FDJ)
FDJ:RegisterNativeData()
assert(FDJ.captured and #FDJ.captured.dungeons == 2, "dungeon scan")
assert(FDJ.captured.dungeons[1].mapID == 501, "map ID position")
assert(FDJ.captured.dungeons[2].markers[1].encounterID == 1102, "encounter ID")
assert(FDJ.captured.build == "70124" and FDJ.captured.verification == "client", "build metadata")
assert(tier == 1, "tier restore")
`, 'native client-data tests');
ok(true, 'native client-data Lua tests');

const toc = fs.readFileSync(path.join(root, 'ForeverDungeonJournal.toc'), 'utf8');
const packageScript = fs.readFileSync(path.join(root, 'tools', 'package.ps1'), 'utf8');
for (const required of ['NativeData.lua', 'CHANGELOG.md', 'docs\\DATA_AUTHOR_GUIDE.md', 'npm test']) {
  ok(packageScript.includes(required), `package allowlist includes ${required}`);
}
ok(toc.includes('## Version: 0.2.0-alpha.1'), 'candidate version in TOC');
console.log(`Tests passed: ${assertions} deterministic suites/assertions (registry, data, provenance, malformed packs, migrations, package metadata).`);
