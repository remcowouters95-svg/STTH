import Anthropic from "@anthropic-ai/sdk";
import { KENNIS } from "./kennis.js";
import { controleerVraag } from "./validatie.js";

const MODEL = "claude-opus-5-5";

function corsHeaders(env) {
  return {
    "Access-Control-Allow-Origin": env.ALLOWED_ORIGIN,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, X-Toegangscode",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
}

function json(env, status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8", ...corsHeaders(env) },
  });
}

// Vergelijking in constante tijd, zodat de code niet teken voor teken te raden is.
function codeKlopt(gegeven, verwacht) {
  if (typeof gegeven !== "string" || typeof verwacht !== "string") return false;
  const enc = new TextEncoder();
  const a = enc.encode(gegeven);
  const b = enc.encode(verwacht);
  if (a.length !== b.length) return false;
  let verschil = 0;
  for (let i = 0; i < a.length; i++) verschil |= a[i] ^ b[i];
  return verschil === 0;
}

// Dagplafond via KV. Zonder TELLER binding wordt dit overgeslagen.
async function binnenDagplafond(env) {
  if (!env.TELLER) return true;
  const max = Number(env.MAX_PER_DAG || "0");
  if (!max) return true;
  const sleutel = "dag:" + new Date().toISOString().slice(0, 10);
  const huidig = Number((await env.TELLER.get(sleutel)) || "0");
  if (huidig >= max) return false;
  await env.TELLER.put(sleutel, String(huidig + 1), { expirationTtl: 60 * 60 * 48 });
  return true;
}

async function beantwoord(env, vraag) {
  const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  const response = await client.messages.create({
    model: MODEL,
    max_tokens: 4000,
    output_config: { effort: "high" },
    cache_control: { type: "ephemeral" },
    system: KENNIS,
    messages: [{ role: "user", content: vraag }],
  });

  if (response.stop_reason === "refusal") {
    return "Deze vraag kan niet worden beantwoord. Formuleer de vraag anders of leg haar voor aan een collega.";
  }

  const tekst = response.content
    .filter((blok) => blok.type === "text")
    .map((blok) => blok.text)
    .join("\n")
    .trim();

  if (response.stop_reason === "max_tokens") {
    return tekst + "\n\n(Het antwoord is afgebroken omdat het te lang werd. Stel een gerichtere vraag.)";
  }
  return tekst;
}

export default {
  async fetch(request, env) {
    if (!env.ALLOWED_ORIGIN || !env.TOEGANGSCODE || !env.ANTHROPIC_API_KEY) {
      return new Response("Worker is niet volledig geconfigureerd.", { status: 500 });
    }

    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders(env) });
    }
    if (request.method !== "POST" || url.pathname !== "/vraag") {
      return json(env, 404, { fout: "Onbekend pad." });
    }

    const origin = request.headers.get("Origin");
    if (origin && origin !== env.ALLOWED_ORIGIN) {
      return json(env, 403, { fout: "Deze herkomst is niet toegestaan." });
    }

    if (!codeKlopt(request.headers.get("X-Toegangscode"), env.TOEGANGSCODE)) {
      return json(env, 401, { fout: "Toegangscode onjuist." });
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json(env, 400, { fout: "Ongeldige aanvraag." });
    }

    const reden = controleerVraag(body?.vraag);
    if (reden) return json(env, 400, { fout: reden });

    if (!(await binnenDagplafond(env))) {
      return json(env, 429, { fout: "Het dagelijkse maximum aan vragen is bereikt. Probeer het morgen opnieuw." });
    }

    try {
      const antwoord = await beantwoord(env, body.vraag.trim());
      return json(env, 200, { antwoord });
    } catch (error) {
      // Inhoud van vraag of antwoord wordt bewust nooit gelogd.
      if (error instanceof Anthropic.RateLimitError) {
        return json(env, 503, { fout: "De dienst is tijdelijk druk. Probeer het over een minuut opnieuw." });
      }
      if (error instanceof Anthropic.AuthenticationError) {
        console.error("API sleutel ongeldig");
        return json(env, 500, { fout: "De dienst is niet goed geconfigureerd. Meld dit bij de beheerder." });
      }
      if (error instanceof Anthropic.APIError) {
        console.error("API fout", error.status);
        return json(env, 502, { fout: "De dienst gaf een fout terug. Probeer het later opnieuw." });
      }
      console.error("Onverwachte fout", error?.name);
      return json(env, 500, { fout: "Er ging iets mis. Probeer het later opnieuw." });
    }
  },
};
