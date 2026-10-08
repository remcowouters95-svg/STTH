# CLAUDE.md

Context voor Claude Code in deze repository.

## Waar gaat dit over

Tools en analyses voor het team Toezicht en Handhaving Stralingstoepassingen (ST TH) van de ANVS.
Doel: administratieve last verlagen en zichtbaar maken waar tijd verdwijnt.

## Belangrijk: deze repository is openbaar

* Zet nooit persoonsgegevens, mailinhoud, zaakinhoud, zaaknummers van echte zaken,
  namen van ondertoezichtstaanden of exports uit KIM, CM of Outlook in deze repository.
* Gebruik in voorbeelden altijd placeholders zoals `voornaam.achternaam@anvs.nl` en
  verzonnen zaaknummers.
* `.gitignore` blokkeert `.pbix`, `.xlsx` en `.csv` exports buiten `knelpuntanalyse/meetlog/`.
  Haal die regel niet weg.

## Omgeving waarin de code draait

* Werklaptop: Power BI Desktop is aanwezig. VBA, PowerShell, cmd en installatie van software
  zijn geblokkeerd. Acrobat JavaScript werkt wel.
* Power Query (M) en DAX in deze repo worden met de hand in Power BI Desktop geplakt.
  Claude Code kan ze hier niet uitvoeren; controleer ze daarom zorgvuldig op syntax
  (komma's tussen stappen, haakjes, `let ... in`), op kolomnamen en op consistentie
  tussen de queries.
* Python kan op de ODC Noord VM (JupyterLab via Citrix). Daar mag geen data naar een
  externe API.

## Mappen

* `knelpuntanalyse/PLAN.md` het plan met hypotheses, indicatoren K1 tot en met K12,
  toetsmomenten en stappenplan. Dit is de bron van waarheid voor definities.
* `knelpuntanalyse/powerquery/` een `.pq` bestand per Power BI query. De bestandsnaam is de
  querynaam in Power BI.
* `knelpuntanalyse/HANDLEIDING.md` stappen voor collega's om het rapport in Power BI Desktop op
  te bouwen.
* `knelpuntanalyse/dax/metingen.dax` alle DAX metingen voor de meetlog.
* `knelpuntanalyse/meetlog/` lege sjablonen voor meetlog en tijdsmeting (alleen
  geaggregeerde getallen, nooit ruwe data).

## Werkafspraken

* Schrijf in het Nederlands. Gebruik in lopende tekst geen gedachtestreepjes.
* Wijzig je de definitie van een indicator, verhoog dan de versie in `PLAN.md` en in
  `meetlog/meetlog.csv`, en noteer het in de wijzigingslog onderaan `PLAN.md`.
* Power BI leest alleen. Schrijf geen code die mail verstuurt, verplaatst of verwijdert.
* Afhankelijkheden tussen queries: `Trefwoorden`, `Streeftermijnen` en `Werkdagen` hebben geen
  bron; `Mail` gebruikt `Trefwoorden`; `Doorlooptijd`, `MailPerZaak` en `UrenPerDag` gebruiken
  `Mail`; `Doorlooptijd` en `UrenPerDag` gebruiken ook `Werkdagen`; `KIM` gebruikt
  `Streeftermijnen`.
* Houd `knelpuntanalyse/HANDLEIDING.md` bij als je een query toevoegt of een instelling wijzigt.

## Volgende taken voor Claude Code

Zie de open punten in het stappenplan van `knelpuntanalyse/PLAN.md`.

Afgerond op 8 oktober 2026: review van alle `.pq` bestanden, werkdagenversie van de
doorlooptijd (`Werkdagen`, K6w tot en met K8w) en `HANDLEIDING.md`.

Mogelijke volgende taken:

1. Zodra de echte KIM export er is: kolomnamen in `KIM.pq` en zaaktypen in
   `Streeftermijnen.pq` aanpassen.
2. Een Python notebook voor de ODC Noord VM dat de meetlog vergelijkt met de bandbreedte van
   de nulmeting.
