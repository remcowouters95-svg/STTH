# Wettelijke analyse stralingsbescherming

Een webpagina waarop teamleden een vraag kunnen stellen over de toepassing van de
Kernenergiewet en de onderliggende regelgeving (Bbs, Rbs, ANVS-verordening, Bvser) op
radioactieve objecten, postpakketten, transporten en overdrachten.

De antwoorden komen van een AI taalmodel. Dat staat zichtbaar op de pagina en bij elk
antwoord. Antwoorden zijn een hulpmiddel bij de voorbereiding, geen juridisch oordeel. De
gebruiker controleert artikelen en grenswaarden altijd tegen de actuele wettekst en legt
twijfel voor aan juridische zaken.

Dit is een demo om intern voor te leggen. Gebruik voor echt zaakwerk vraagt afstemming met
de organisatie (informatiebeveiliging, privacy, AI beleid).

## Hoe het werkt

```
browser (docs/index.html op GitHub Pages)
   │  POST /vraag  { vraag }  + header X-Toegangscode
   ▼
Cloudflare Worker (worker/)
   │  controleert toegangscode en invoer
   │  stuurt vraag met de kennisbasis als instructie naar het taalmodel
   ▼
AI taalmodel  →  antwoord terug naar de browser
```

* De pagina is statisch. De sleutel voor het taalmodel staat alleen als secret in de Worker.
* De Worker eist een gedeelde toegangscode, accepteert alleen aanroepen vanaf de eigen
  Pages URL, weigert vragen met zaaknummers, e-mailadressen, telefoonnummers, kentekens of
  vergelijkbare persoonsgegevens, en kent optioneel een dagelijks maximum aan vragen.
* Elke vraag staat op zichzelf. Er wordt geen gesprek bijgehouden en vraag en antwoord
  worden nergens opgeslagen of gelogd.
* De kennisbasis (`worker/src/kennis.js`) bevat de toetsingsvolgorde, een overzicht van
  de regelgeving en eerder vastgestelde interpretaties. De wetteksten zelf zitten er niet
  in; het model werkt uit eigen kennis plus deze instructies.

## Zelf in gebruik nemen

Nodig: een GitHub account, een gratis Cloudflare account en een API sleutel van de
leverancier van het taalmodel.

1. Worker installeren en deployen

   ```bash
   cd worker
   npm install
   npx wrangler login
   npx wrangler secret put ANTHROPIC_API_KEY
   npx wrangler secret put TOEGANGSCODE
   npx wrangler deploy
   ```

   Zet in `worker/wrangler.toml` bij `ALLOWED_ORIGIN` de URL van de GitHub Pages site
   (bijvoorbeeld `https://gebruikersnaam.github.io`) en deploy opnieuw. Wrangler toont
   na deployen de URL van de Worker.

2. Frontend koppelen

   Vul in `docs/index.html` bij `WORKER_URL` de Worker URL in en commit.

3. GitHub Pages aanzetten

   Repository instellingen, Pages, bron "Deploy from a branch", branch kiezen, map `/docs`.

4. Toegangscode delen met het team, buiten deze repository om.

Optioneel dagplafond: maak een KV namespace (`npx wrangler kv namespace create TELLER`),
zet het id in `wrangler.toml` onder `kv_namespaces` en kies `MAX_PER_DAG`.

## Lokaal testen

```bash
cd worker
cp .dev.vars.example .dev.vars   # vul de waarden in
npm test                         # invoercontrole en toegangscontrole, zonder API aanroep
npx wrangler dev                 # Worker op http://localhost:8787
```

Open daarna `docs/index.html` via een lokale webserver (bijvoorbeeld
`python3 -m http.server 8000` in `docs/`) met `WORKER_URL` op `http://localhost:8787` en
`ALLOWED_ORIGIN=http://localhost:8000` in `.dev.vars`.

## Kosten

Per vraag worden de kennisbasis (gecached) en de vraag verstuurd en een antwoord van
enkele honderden tot enkele duizenden tokens teruggegeven. Reken op enkele centen tot
circa tien cent per vraag, afhankelijk van de lengte van het antwoord. Het dagplafond
begrenst de totale kosten.

## Spelregels voor deze repository

* Geen zaakinhoud, zaaknummers of persoonsgegevens in code, kennisbasis of voorbeelden.
* Geen sleutels of toegangscodes in de repository. `.dev.vars` staat in `.gitignore`.
* Wijzigingen in de kennisbasis alleen op basis van vastgestelde lijnen, met vermelding
  van de bron in het commitbericht.
