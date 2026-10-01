import assert from "node:assert/strict";
import { controleerVraag } from "../src/validatie.js";
import worker from "../src/index.js";

// Invoercontrole
assert.equal(controleerVraag("Is een horloge met radiumverf vrijgesteld voor voorhanden hebben?"), null);
assert.equal(controleerVraag("Ra-226, 5 Bq/g, 800 Bq totaal, in een postpakket uit Duitsland."), null);
assert.match(controleerVraag("Zaak ANVS-PP-2026/0000001: mag dit?"), /zaaknummer/);
assert.match(controleerVraag("Mail van jan@voorbeeld.nl"), /e-mailadres/);
assert.match(controleerVraag("Bel 06-12345678"), /telefoonnummer/);
assert.match(controleerVraag(""), /leeg/);
assert.match(controleerVraag("x".repeat(2001)), /langer/);
assert.match(controleerVraag(42), /ontbreekt/);

// Worker zonder API aanroep: configuratie, CORS, toegangscode en validatie
const env = {
  ALLOWED_ORIGIN: "https://voorbeeld.github.io",
  TOEGANGSCODE: "geheim",
  ANTHROPIC_API_KEY: "sk-ant-test",
  MAX_PER_DAG: "1",
};

async function call(method, path, { headers = {}, body } = {}) {
  const req = new Request("https://worker.test" + path, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  return worker.fetch(req, env);
}

let res = await worker.fetch(new Request("https://worker.test/vraag", { method: "POST" }), {});
assert.equal(res.status, 500);

res = await call("OPTIONS", "/vraag");
assert.equal(res.status, 204);
assert.equal(res.headers.get("Access-Control-Allow-Origin"), env.ALLOWED_ORIGIN);

res = await call("GET", "/vraag");
assert.equal(res.status, 404);

res = await call("POST", "/vraag", { headers: { Origin: "https://kwaad.example" }, body: { vraag: "x" } });
assert.equal(res.status, 403);

res = await call("POST", "/vraag", { headers: { "X-Toegangscode": "fout" }, body: { vraag: "x" } });
assert.equal(res.status, 401);

res = await call("POST", "/vraag", { headers: { "X-Toegangscode": "geheim" }, body: { vraag: "ANVS-PP-2026/0000001" } });
assert.equal(res.status, 400);
assert.match((await res.json()).fout, /zaaknummer/);

// Dagplafond met een nep KV
let opslag = {};
const envMetTeller = {
  ...env,
  TELLER: {
    async get(k) { return opslag[k] ?? null; },
    async put(k, v) { opslag[k] = v; },
  },
};
// De eerste aanroep passeert het plafond en bereikt de API, die met een nepsleutel faalt.
res = await worker.fetch(new Request("https://worker.test/vraag", {
  method: "POST", headers: { "X-Toegangscode": "geheim" }, body: JSON.stringify({ vraag: "Wat is NORM?" }),
}), envMetTeller);
assert.notEqual(res.status, 429);
res = await worker.fetch(new Request("https://worker.test/vraag", {
  method: "POST", headers: { "X-Toegangscode": "geheim" }, body: JSON.stringify({ vraag: "Wat is NORM?" }),
}), envMetTeller);
assert.equal(res.status, 429);

console.log("Alle controles geslaagd.");

// Geen valse treffers op gewone vaktermen
for (const v of [
  "Art. 4.24 Bbs noemt alleen H-3 en Pm-147. Geldt dat ook voor Ra-226?",
  "Waar staat de vrijstellingstabel in BWBR0040179 en wat is tabel B kolom 3?",
  "VSG tabel 2.2.7.2.2.1: 1 x 10^4 Bq en 10 Bq/g, factor tien bij NORM?",
  "Een zending van 8000 MBq Cs-137 vanuit België, Bvser art. 27 lid 3.",
]) assert.equal(controleerVraag(v), null, v);
console.log("Geen valse treffers.");
