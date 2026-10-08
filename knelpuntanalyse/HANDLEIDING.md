# Handleiding knelpuntanalyse in Power BI Desktop

Met deze stappen bouw je het rapport voor de knelpuntanalyse op je eigen werklaptop op. Je hebt
alleen Power BI Desktop nodig. Alles is alleen lezend: er wordt niets in Outlook, KIM of CM
gewijzigd. Definities en achtergrond staan in `PLAN.md`.

Reken op ongeveer een uur voor de eerste keer, exclusief laadtijd van de mailbox.

## Voor je begint

1. Download de map `knelpuntanalyse` uit deze repository (de `.pq` en `.dax` bestanden zijn
   gewone tekstbestanden; open ze met Kladblok).
2. Bewaar het rapport als `.pbix` op je laptop of op een beveiligde netwerkmap, nooit in deze
   repository en niet in de Power BI service.
3. Gebruik alleen je eigen mailbox, tenzij leidinggevende en FG akkoord hebben gegeven voor een
   teammailbox.

## Stap 1: een query aanmaken (zo gaat het elke keer)

1. **Start** > **Gegevens ophalen** > **Lege query**. De Power Query-editor opent.
2. **Start** > **Geavanceerde editor**. Selecteer alles wat er staat en vervang het door de
   volledige inhoud van het `.pq` bestand, inclusief de regels met `//`.
3. Klik op **Gereed**. Staat er onderaan "Er zijn geen syntaxisfouten gedetecteerd", dan is het
   goed.
4. Geef de query rechts bij **Eigenschappen** precies de naam van het bestand zonder `.pq`
   (bijvoorbeeld `Mail`). Hoofdletters tellen: andere queries zoeken op deze naam.

## Stap 2: de queries in deze volgorde

Een query kan pas werken als de queries waar hij van afhangt al bestaan. Houd daarom deze
volgorde aan.

| Nr | Bestand | Wat moet je aanpassen | Laden in model |
| --- | --- | --- | --- |
| 1 | `Trefwoorden.pq` | niets | uit |
| 2 | `Streeftermijnen.pq` | zaaktypen en termijnen, zodra de KIM export er is | uit |
| 3 | `Werkdagen.pq` | `Startjaar` en `Eindjaar` als de meting buiten 2026 en 2027 valt | aan |
| 4 | `Mail.pq` | `Adres` (je eigen mailadres), `Startdatum`, `Einddatum` | aan |
| 5 | `Doorlooptijd.pq` | `Peildatum` | aan |
| 6 | `MailPerZaak.pq` | niets | aan |
| 7 | `UrenPerDag.pq` | niets | aan |
| 8 | `KIM.pq` | `Pad` naar de KIM export en `Peildatum` | aan |

Laden uitzetten: klik met de rechtermuisknop op de query en haal het vinkje bij
**Laden inschakelen** weg. De query blijft dan bruikbaar voor andere queries, maar komt niet als
tabel in het rapport.

Heb je nog geen KIM export, sla dan `Streeftermijnen` en `KIM` over. De rest werkt zonder.

**Bij `Mail` vraagt Power BI om aanmelding.** Kies **Microsoft-account** en meld je aan met je
werkaccount. Vraagt Power BI naar privacyniveaus, kies dan voor alle bronnen **Organisatie**.

Klik daarna op **Sluiten en toepassen**. Het eerste laden van zes maanden mail kan lang duren.

## Stap 3: instellingen die bij elkaar horen

Deze vier waarden horen bij dezelfde meetperiode en pas je altijd samen aan:

| Query | Instelling | Nulmeting |
| --- | --- | --- |
| `Mail` | `Startdatum` | `#date(2026, 4, 1)` |
| `Mail` | `Einddatum` | `#date(2026, 9, 30)` |
| `Doorlooptijd` | `Peildatum` | `#datetime(2026, 9, 30, 23, 59, 59)` |
| `KIM` | `Peildatum` | `#date(2026, 9, 30)` |

`Werkdagen` moet de hele periode omvatten. Wijzig je verder niets, dan blijven de metingen
vergelijkbaar. Wijzig je toch iets aan een definitie of aan `Trefwoorden`, lees dan eerst de regels
in `PLAN.md` over versienummers.

## Stap 4: relatie en metingen

1. Ga naar de **Modelweergave** en sleep `MailPerZaak[Zaaknummer]` naar `KIM[Zaaknummer]`.
   Geeft Power BI een melding over dubbele waarden, dan staat een zaak meer dan eens in de KIM
   export; meld dat, want dan klopt K9 niet.
2. Optioneel: klik met rechts op `Werkdagen` > **Markeren als datumtabel** met kolom `Datum`, en
   leg een relatie van `Werkdagen[Datum]` naar `Mail[Datum]`. Dan kun je per maand of week
   filteren met dezelfde kalender.
3. Maak in de **Rapportweergave** per meting een nieuwe meting aan: kies de tabel die in
   `dax/metingen.dax` boven de meting staat, dan **Modelleren** > **Nieuwe meting**, en plak de
   tekst vanaf de naam (bijvoorbeeld `K2 Aandeel standaardmail =`) tot aan de volgende lege regel.
4. Zet de metingen K2, K4, K7, K7w, K9 en K12 op opmaak **Percentage**.

## Stap 5: controle voor je meetwaarden noteert

1. **Richting.** Maak een tabelvisual met `Mail[Map]` en `Mail[Richting]` en het aantal rijen.
   Je map met verzonden items moet op Uitgaand staan, al het andere op Inkomend. Heet die map bij
   jou anders, voeg de naam (kleine letters) toe aan `MappenUit` in `Mail`.
2. **Kolommen.** Zijn `ConversationTopic` of `DateTimeSent` in `Mail` helemaal leeg, dan levert
   jouw versie van de Exchange connector andere kolomnamen. Meld dat; dan zijn K5 tot en met K8
   niet bruikbaar.
3. **K12.** Ligt het aandeel Onbekend boven 20%, vul dan eerst `Trefwoorden` aan (stappenplan
   week 2) voor je de andere waarden noteert.

## Stap 6: meetlog invullen

1. Maak een pagina **Meetlog** met een kaartvisual per meting.
2. Zet een filter op paginaniveau op de periode.
3. Neem de waarden over in `meetlog/meetlog.csv`, alleen geaggregeerde getallen.
4. Sla het `.pbix` op met de periode in de naam, bijvoorbeeld
   `knelpuntanalyse_2026-04_2026-09.pbix`, buiten deze repository.

## Als er iets misgaat

| Melding | Oorzaak en oplossing |
| --- | --- |
| "De import Mail komt niet overeen met exports" of een vergelijkbare melding | De naam van een query klopt niet. Controleer de naam bij Eigenschappen. |
| "De kolom ... van de tabel is niet gevonden" | De connector of de KIM export gebruikt een andere kolomnaam. Pas de naam aan in de stap `Kolommen` van de query. |
| "Formula.Firewall" | Zet bij **Bestand** > **Opties en instellingen** > **Gegevensbronsinstellingen** alle bronnen op privacyniveau **Organisatie**. |
| Laden duurt erg lang | Verkort tijdelijk de periode in `Mail` om te testen, en zet daarna de juiste periode terug. |
