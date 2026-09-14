/*
 * Drives the prototype's own seal() with edge cases and records what it produces.
 *
 * The Swift CanonicalJSON encoder has to reproduce JSON.stringify byte for
 * byte, and the seeded ledger only exercises plain ASCII-plus-accents strings.
 * These cases add the parts that are easy to get wrong and invisible when
 * wrong: integral numbers printing without a fractional part, booleans, nulls,
 * nested arrays, control characters, and the reserved-name rename.
 *
 * The expected values come from running the prototype's seal(), not from
 * reimplementing it. If Swift disagrees with this file, Swift is wrong.
 */

import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import vm from "node:vm";
import path from "node:path";

const SOURCE = "source/Bridge_RC2_1.html";
const OUT = "Bridge/Tests/BridgeKitTests/Fixtures/ChainFixture.json";

/* ---- a small in-memory IndexedDB, enough for DB.open/load/put ---- */

function fakeIndexedDB() {
  const dbs = {};
  const later = (fn) => queueMicrotask(fn);
  return {
    open(name) {
      const req = {};
      const store = (dbs[name] ??= { names: new Set(), data: {} });
      const db = {
        objectStoreNames: { contains: (s) => store.names.has(s) },
        createObjectStore(s) {
          store.names.add(s);
          store.data[s] = new Map();
        },
        transaction(which) {
          const t = {};
          later(() => t.oncomplete && t.oncomplete());
          return {
            objectStore(s) {
              const map = (store.data[s] ??= new Map());
              return {
                put: (doc) => ({ result: map.set(doc.id, doc) && doc }),
                getAll: () => ({ result: [...map.values()] }),
                delete: (id) => ({ result: map.delete(id) }),
                clear: () => ({ result: map.clear() }),
              };
            },
            set oncomplete(fn) { t.oncomplete = fn; },
            get oncomplete() { return t.oncomplete; },
            set onerror(fn) { t.onerror = fn; },
          };
        },
      };
      later(() => {
        if (req.onupgradeneeded) { req.result = db; req.onupgradeneeded(); }
        req.result = db;
        if (req.onsuccess) req.onsuccess();
      });
      return req;
    },
  };
}

/* ---- a DOM stub thin enough to boot and thick enough not to throw ---- */

function fakeElement() {
  const el = {
    innerHTML: "", value: "", textContent: "", checked: false,
    style: {}, dataset: {}, classList: { add() {}, remove() {}, toggle() {}, contains: () => false },
    children: [], scrollTop: 0, scrollHeight: 0,
    addEventListener() {}, removeEventListener() {}, appendChild() {}, removeChild() {},
    setAttribute() {}, getAttribute: () => null, removeAttribute() {},
    querySelector: () => fakeElement(), querySelectorAll: () => [],
    closest: () => null, focus() {}, blur() {}, click() {}, remove() {},
    getBoundingClientRect: () => ({ x: 0, y: 0, width: 0, height: 0, top: 0, left: 0 }),
    insertAdjacentHTML() {}, showModal() {}, close() {},
  };
  return el;
}


/* ---- determinism ----------------------------------------------------------
 * The prototype seeds with crypto.randomUUID() and the wall clock, so running
 * this twice produces two different files: every record id changes, every
 * timestamp moves, and the sealed hashes move with them.
 *
 * That makes the generated artefact undiffable. `extract_all.sh` would dirty
 * the tree on every run, and a real change to the seed would arrive buried in
 * a hundred and fifty lines of churn nobody reads.
 *
 * So the harness pins both. Ids come from a counter shaped into a UUID, and the
 * clock is frozen. crypto.subtle stays real: the chain must be sealed with
 * genuine SHA-256 or the fixture proves nothing.
 * -------------------------------------------------------------------------- */

const FROZEN_ISO = "2026-09-14T00:00:00.000Z";
const FROZEN_MS = Date.parse(FROZEN_ISO);
const RealDate = Date;

function deterministicCrypto() {
  let counter = 0;
  const hex = (n, width) => Math.abs(n).toString(16).padStart(width, "0").slice(-width);
  return {
    subtle: globalThis.crypto.subtle,
    getRandomValues: (array) => {
      for (let i = 0; i < array.length; i++) array[i] = (counter * 31 + i) & 0xff;
      counter += 1;
      return array;
    },
    randomUUID: () => {
      const n = ++counter;
      /* Shaped like a v4 UUID so anything that parses one still works. */
      return [hex(n, 8), hex(n, 4), "4" + hex(n, 3), "8" + hex(n * 7, 3), hex(n * 2654435761, 12)]
        .join("-");
    },
  };
}

class FrozenDate extends RealDate {
  constructor(...args) {
    if (args.length === 0) super(FROZEN_MS);
    else super(...args);
  }
  static now() { return FROZEN_MS; }
}

const html = readFileSync(SOURCE, "utf8");
const script = html.slice(html.indexOf("<script>") + 8, html.lastIndexOf("</script>"));

const storage = new Map();
const sandbox = {
  indexedDB: fakeIndexedDB(),
  crypto: deterministicCrypto(),
  console,
  queueMicrotask,
  setTimeout, clearTimeout, setInterval, clearInterval,
  requestAnimationFrame: (fn) => setTimeout(fn, 0),
  fetch: () => Promise.reject(new Error("offline in the harness")),
  navigator: { language: "es-MX", clipboard: { writeText: async () => {} }, gpu: undefined,
               userAgent: "chain-fixture" },
  location: { href: "bridge.armada.local", hash: "", reload() {} },
  matchMedia: () => ({ matches: false, addEventListener() {}, addListener() {} }),
  localStorage: {
    getItem: (k) => (storage.has(k) ? storage.get(k) : null),
    setItem: (k, v) => storage.set(k, String(v)),
    removeItem: (k) => storage.delete(k),
    clear: () => storage.clear(),
  },
  document: {
    documentElement: fakeElement(), body: fakeElement(),
    getElementById: () => fakeElement(), createElement: () => fakeElement(),
    querySelector: () => fakeElement(), querySelectorAll: () => [],
    addEventListener() {}, removeEventListener() {},
  },
  URL, Blob: class { constructor() {} }, TextEncoder, TextDecoder,
  Intl, Math, Date: FrozenDate, JSON,
};
sandbox.window = sandbox;
sandbox.globalThis = sandbox;

const context = vm.createContext(sandbox);
vm.runInContext(script, context, { filename: "Bridge_RC2_1.html" });
await new Promise((r) => setTimeout(r, 400));

/* Every case is sealed at a fixed timestamp so the fixture is reproducible. */
const AT = "2026-09-14T00:00:00.000Z";
const CASES = [
  { name: "plain",            es: "sellado",              en: "sealed",             actor: "m.rios",  extra: {} },
  { name: "accents",          es: "sellado (emisión)",    en: "sealed (issuance)",  actor: "sistema", extra: { key: "CFDI …8C2F" } },
  { name: "integral number",  es: "monto",                en: "amount",             actor: "m.rios",  extra: { amount: 12000 } },
  { name: "fractional",       es: "tolerancia",           en: "tolerance",          actor: "m.rios",  extra: { pct: 0.05 } },
  { name: "bool and null",    es: "banderas",             en: "flags",              actor: "m.rios",  extra: { paused: false, escalated: true, owner: null } },
  { name: "array",            es: "historial",            en: "history",            actor: "m.rios",  extra: { history: ["a", "b"], counts: [1, 2, 3] } },
  { name: "nested object",    es: "caso",                 en: "case",               actor: "m.rios",  extra: { match: { po: "PO-1", delta: 0 } } },
  { name: "reserved rename",  es: "reservado",            en: "reserved",           actor: "m.rios",  extra: { seq: 99, hash: "nope", other: 1 } },
  { name: "quotes and slash", es: 'comilla " y \\ barra', en: 'quote " and \\ slash', actor: "m.rios", extra: { note: "line\nbreak\ttab" } },
  { name: "emoji",            es: "sello ✅",              en: "seal ✅",             actor: "m.rios",  extra: { mark: "⟦x⟧" } },
];

const seal = vm.runInContext("seal", context);
const S = vm.runInContext("S", context);

/* Seal each case onto a chain that starts empty, so seq and prevHash are predictable. */
S.ledger.length = 0;
const entries = [];
for (const c of CASES) {
  const e = await seal(c.es, c.en, c.actor, c.extra, `fixture-${entries.length + 1}`);
  /* seal() stamps its own `at`; rewrite to the fixed one and re-derive the hash the
     same way seal() does, so the fixture is stable across runs. */
  const prev = entries.length ? entries[entries.length - 1].hash : "genesis";
  const reserved = ["id", "seq", "at", "actor", "es", "en", "prevHash", "hash"];
  const extra = {};
  for (const [k, v] of Object.entries(c.extra)) extra[reserved.includes(k) ? "x_" + k : k] = v;
  const payload = JSON.stringify({ es: c.es, en: c.en, actor: c.actor, ...extra });
  const sha = vm.runInContext("sha256", context);
  const hash = await sha(prev + AT + c.actor + payload);
  entries.push({ name: c.name, id: e.id, seq: entries.length + 1, at: AT, actor: c.actor,
                 es: c.es, en: c.en, extra: c.extra, payload, prevHash: prev, hash });
}

mkdirSync(path.dirname(OUT), { recursive: true });
writeFileSync(OUT, JSON.stringify({
  note: "Generated by tools/chain_fixture.mjs from the prototype's own seal(). " +
        "Expected values are authoritative; if Swift disagrees, Swift is wrong.",
  rule: "hash = sha256((prev?.hash ?? 'genesis') + at + actor + JSON.stringify({es, en, actor, ...extra}))",
  entries,
}, null, 2) + "\n");

console.log(`chain fixture: ${entries.length} cases -> ${OUT}`);
for (const e of entries) console.log(`        ${e.name.padEnd(18)} ${e.hash.slice(0, 16)}…  ${e.payload.slice(0, 58)}`);
process.exit(0);
