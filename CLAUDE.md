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
* `knelpuntanalyse/dax/metingen.dax` alle DAX metingen voor de meetlog.
* `knelpuntanalyse/meetlog/` lege sjablonen voor meetlog en tijdsmeting (alleen
  geaggregeerde getallen, nooit ruwe data).

## Werkafspraken

* Schrijf in het Nederlands. Gebruik in lopende tekst geen gedachtestreepjes.
* Wijzig je de definitie van een indicator, verhoog dan de versie in `PLAN.md` en in
  `meetlog/meetlog.csv`, en noteer het in de wijzigingslog onderaan `PLAN.md`.
* Power BI leest alleen. Schrijf geen code die mail verstuurt, verplaatst of verwijdert.
* Afhankelijkheden tussen queries: `Trefwoorden` en `Streeftermijnen` hebben geen bron;
  `Mail` gebruikt `Trefwoorden`; `Doorlooptijd`, `MailPerZaak` en `UrenPerDag` gebruiken
  `Mail`; `KIM` gebruikt `Streeftermijnen`.

## Volgende taken voor Claude Code

Zie de open punten in het stappenplan van `knelpuntanalyse/PLAN.md`. Goede eerste taken:

1. Een review van alle `.pq` bestanden op syntax en consistentie van kolomnamen.
2. Een werkdagenversie van de doorlooptijd (datumtabel met feestdagen), als optie naast
   de huidige kalendertijd.
3. Een korte handleiding `knelpuntanalyse/HANDLEIDING.md` voor collega's: in welke volgorde
   de queries in Power BI Desktop worden aangemaakt.
