/*
 * Runs the prototype's own seed() and dumps the result.
 *
 * The seed is procedural — loops, derived UUIDs, arithmetic on amounts — so
 * reading it out of the source by pattern would be transcription with extra
 * steps. Instead the real script runs here against a stubbed browser, and we
 * take what it actually produces. Whatever the prototype seeds, Swift seeds.
 */

import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import vm from "node:vm";
import path from "node:path";

const SOURCE = "source/Bridge_RC2_1.html";
const OUT = "Bridge/Sources/BridgeKit/Resources/Seed.json";

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
               userAgent: "seed-harness" },
  location: { href: "bridge.armada.local", hash: "", reload() {} },
  matchMedia: () => ({ matches: false, addEventListener() {}, addListener() {} }),
  localStorage: {
    getItem: (k) => (storage.has(k) ? storage.get(k) : null),
    setItem: (k, v) => storage.set(k, String(v)),
    removeItem: (k) => storage.delete(k),
    clear: () => storage.clear(),
  },
  document: {
    documentElement: fakeElement(),
    body: fakeElement(),
    getElementById: () => fakeElement(),
    createElement: () => fakeElement(),
    querySelector: () => fakeElement(),
    querySelectorAll: () => [],
    addEventListener() {}, removeEventListener() {},
  },
  URL, Blob: class { constructor() {} }, TextEncoder, TextDecoder,
  Intl, Math, Date: FrozenDate, JSON,
};
sandbox.window = sandbox;
sandbox.globalThis = sandbox;

const context = vm.createContext(sandbox);
vm.runInContext(script, context, { filename: "Bridge_RC2_1.html" });

/* The boot IIFE at the foot of the script opens the database, seeds and renders.
   Give it a few turns of the loop, then take what is in the store. */
await new Promise((r) => setTimeout(r, 400));

const S = vm.runInContext("S", context);
const STORES = vm.runInContext("STORES", context);

if (!S || !STORES) {
  console.error("the script did not expose S / STORES; the harness needs updating");
  process.exit(1);
}

const seeded = Object.fromEntries(STORES.map((s) => [s, S[s] ?? []]));
const counts = Object.entries(seeded)
  .filter(([, v]) => v.length)
  .sort((a, b) => b[1].length - a[1].length);

if (!counts.length) {
  console.error("seed produced nothing; the boot sequence probably threw");
  process.exit(1);
}

mkdirSync(path.dirname(OUT), { recursive: true });
writeFileSync(OUT, JSON.stringify({
  schema: "armada-bridge",
  version: "0.2",
  note: "Generated by tools/seed_harness.mjs from the prototype's own seed(). Do not edit.",
  ...seeded,
}, null, 2) + "\n");

const total = counts.reduce((n, [, v]) => n + v.length, 0);
console.log(`seed: ${total} records across ${counts.length} stores -> ${OUT}`);
for (const [name, rows] of counts) console.log(`        ${name.padEnd(14)} ${String(rows.length).padStart(4)}`);
const empty = STORES.filter((s) => !seeded[s].length);
if (empty.length) console.log(`        (empty: ${empty.join(", ")})`);

/* The script installs timers and an on-device model poller, so the event loop
   never drains on its own. We have what we came for. */
process.exit(0);
