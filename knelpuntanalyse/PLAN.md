# Plan knelpuntanalyse administratieve last

Versie definities: **v1** (8 oktober 2026)

## Doel en toetsvraag

Dit plan legt vast welke knelpunten we meten, hoe we ze meten en wanneer iets als knelpunt
telt, zodat elke latere meting tegen dezelfde nulmeting kan worden gelegd.

**Toetsvraag:** waar gaat de administratieve tijd van het toezichtteam ST naartoe, en is die
last na een maatregel (standaardtekst, macro, RPA, kennisbank) aantoonbaar kleiner geworden?

Drie dingen blijven telkens hetzelfde: de definities van de indicatoren, het filter op de data
en de versie van de trefwoordtabel. Alleen dan is een verschil tussen twee metingen een echt
verschil.

## Uitgangspunten

Alles draait op Power BI Desktop op de werklaptop en is alleen lezend: er wordt niets in
Outlook, KIM of CM gewijzigd.

1. **Lokaal.** Het rapport blijft een .pbix op de laptop of een beveiligde netwerkmap. Niet
   publiceren naar de Power BI service zonder akkoord van de FG.
2. **Eigen mailbox eerst.** Teammailboxen of de postbus DDA straling pas na afstemming met
   leidinggevende en FG.
3. **Vast meetvenster.** Elke meting beslaat een afgesloten periode, nooit "tot vandaag".
4. **Bevroren definities.** Wijzigt een definitie, dan krijgt de indicator een nieuw
   versienummer en wordt de nulmeting opnieuw berekend.
5. **Body inperken.** Classificatie gebruikt alleen onderwerp en de eerste 1500 tekens van de
   body. De kolom Body wordt aan het einde van de query `Mail` verwijderd.
6. **Mail is een indicatie, geen urenregistratie.** Daarom is er een aparte tijdsmeting.
7. **Geen data in deze repository.** Alleen code, sjablonen en geaggregeerde meetwaarden.

## Hypotheses over knelpunten

De drempels zijn een eerste voorstel en worden na de nulmeting met de leidinggevende
vastgesteld.

| Nr | Vermoeden | Indicator | Bron | Knelpunt als (voorstel) | Mogelijke maatregel |
| --- | --- | --- | --- | --- | --- |
| H1 | Veel werk is herhalende standaardmail | K2 aandeel standaardmail; K3 herhaalfactor | Mail, Trefwoorden | K2 > 25% of K3 > 3 | Standaardteksten, kennisbank |
| H2 | Lange stiltes leiden tot statusvragen | K4 aandeel statusvragen; K5 mediane langste stilte | Mail, MailPerZaak | K4 > 10% of K5 > 21 dagen | Vaste terugkoppelmomenten richting melder |
| H3 | Reactieve mail blijft te lang liggen | K6 mediane doorlooptijd; K7 % binnen 120 uur | Doorlooptijd | K7 < 80% | Dagelijkse triage, vaste behandelaar per categorie |
| H4 | Openstaande mail stapelt op | K8 open mails ouder dan 7 dagen | Doorlooptijd | Drie maanden achter elkaar stijgend | Opvolglijst uit het rapport als werkvoorraad |
| H5 | Zaken overschrijden hun termijn | K9 % open zaken over streeftermijn | KIM | K9 > 20% | Prioriteren op zaaktype, risicogestuurd toezicht |
| H6 | Dossierhandelingen kosten veel tijd | K10 minuten per week | Mail, tijdsmeting | > 4 uur per week per inspecteur | Acrobat JavaScript, RPA voor opslaan en archiveren |
| H7 | De werkdag is versnipperd door mail | K11 uren per dag met uitgaande mail | UrenPerDag | Mediaan > 6 | Vaste mailblokken |

K12 (aandeel Onbekend) is een kwaliteitscontrole: ligt die boven 20%, dan zijn K2 en K4
onbetrouwbaar en wordt eerst de trefwoordtabel aangevuld.

**Werkdagvarianten (optioneel).** Naast K6, K7 en K8 in kalendertijd zijn er K6w, K7w en K8w in
werkdagen. Tijd in weekenden en op feestdagen van de rijksoverheid (query `Werkdagen`) telt
daarbij niet mee; een werkdag telt volledig. Een mail die vrijdag om 16.00 binnenkomt en maandag om
10.00 is beantwoord, heeft een doorlooptijd van 0,75 werkdag (in kalendertijd 66 uur). Voorstel
voor de drempels: K7w telt binnen 5 werkdagen, K8w telt open mails ouder dan 5 werkdagen. De
kalendervarianten blijven de hoofdindicatoren voor H3 en H4 tot de leidinggevende anders besluit.

## Meetlog

De meetwaarden staan in `meetlog/meetlog.csv`. Vergelijk alleen indicatoren met hetzelfde
versienummer. Lees de waarden af van een pagina Meetlog in het rapport met een kaartvisual per
indicator en het periodefilter op paginaniveau.

## Tijdsmeting

Twee gewone werkweken (niet rond een vakantie) per handeling turven, en per handeling vijf keer
met een stopwatch de duur meten. Sjabloon: `meetlog/tijdsmeting.csv`. Bij voorkeur houdt een
collega dezelfde tabel bij. Herhaal na elke maatregel exact dezelfde meting.

## Queries en metingen

| Bestand | Querynaam in Power BI | Afhankelijk van |
| --- | --- | --- |
| `powerquery/Trefwoorden.pq` | Trefwoorden | geen |
| `powerquery/Streeftermijnen.pq` | Streeftermijnen | geen |
| `powerquery/Werkdagen.pq` | Werkdagen | geen |
| `powerquery/Mail.pq` | Mail | Trefwoorden |
| `powerquery/Doorlooptijd.pq` | Doorlooptijd | Mail, Werkdagen |
| `powerquery/MailPerZaak.pq` | MailPerZaak | Mail |
| `powerquery/UrenPerDag.pq` | UrenPerDag | Mail, Werkdagen |
| `powerquery/KIM.pq` | KIM | Streeftermijnen |
| `dax/metingen.dax` | metingen K1 t/m K12 behalve K10, plus K6w, K7w, K8w | alle tabellen |

Maak de queries aan in de volgorde van de tabel; de stappen staan in `HANDLEIDING.md`. Relatie in
het model: `MailPerZaak[Zaaknummer]` naar `KIM[Zaaknummer]`.

## Toetsmomenten

1. **Nulmeting.** 1 april tot en met 30 september 2026. Noteer naast de waarde ook de laagste
   en hoogste maandwaarde: dat is de normale schommeling.
2. **Kwartaalmeting.** Na afloop van elk kwartaal, de eerste over Q4 2026 in januari 2027.
3. **Voor en na een maatregel.** Een even lange periode voor en na invoering, minimaal acht
   weken elk, met dezelfde versie van alle definities.

**Regels om vergelijkbaar te blijven**

1. Startdatum, Einddatum (`Mail`) en Peildatum (`Doorlooptijd`, `KIM`) horen bij elkaar en
   worden per meting samen aangepast.
2. Sla per meting een kopie van het .pbix op met de periode in de naam, buiten deze repository.
3. Wijzigt `Trefwoorden`, verhoog dan de versie en bereken de nulmeting opnieuw.
4. Reken volumes om naar per werkdag aanwezig, zodat vakantie en ziekte het beeld niet
   vertekenen.

**Wanneer telt een verschil?** Pas als de nieuwe waarde buiten de bandbreedte van de
maandwaarden in de nulmeting valt.

## Stappenplan

- [ ] Week 1: `Mail` laden over april tot en met september
- [ ] Week 1: nagaan of KIM een Excel export per zaak levert met zaaktype, start en einddatum
- [ ] Week 2: `Trefwoorden` aanvullen tot K12 onder 20% ligt, daarna bevriezen als v1
- [ ] Week 2 en 3: tijdsmeting uitvoeren
- [ ] Week 3: `MailPerZaak`, `UrenPerDag` en de DAX metingen inladen
- [ ] Week 4: `KIM` en `Streeftermijnen` inladen zodra de export er is
- [ ] Week 5: pagina Meetlog maken, nulmeting invullen in `meetlog/meetlog.csv`
- [ ] Week 6: drempels bespreken met leidinggevende en vastleggen als doelwaarden
- [ ] Januari 2027: eerste kwartaalmeting over Q4 2026

## Beperkingen en aannames

1. Verwijderde of buiten de mailbox gearchiveerde mail telt niet mee. Mail in de map Verwijderde
   items telt wel mee. Concepten, Postvak UIT, Ongewenste e-mail en Synchronisatieproblemen
   tellen niet mee.
2. Doorlooptijd is per gesprek op ConversationTopic, niet per zaak: elke inkomende mail krijgt
   het eerste uitgaande antwoord daarna in hetzelfde gesprek. Mail zonder gespreksonderwerp telt
   als niet beantwoord, net als telefonische afhandeling.
3. Alleen het eerste geldige zaaknummer per mail wordt herkend (begint met `ANVS-` en bevat een
   `/`), en alleen als het letterlijk in het onderwerp of de eerste 3000 tekens van de body staat.
4. Kolomnamen van de KIM export, zaaktypen en streeftermijnen zijn aannames tot de echte export
   er is. Ook de kolomnamen van de Exchange connector kunnen per versie verschillen; `Mail` haalt
   ConversationTopic en DateTimeSent zo nodig uit de kolom Attributes.
5. K6, K7 en K8 zijn in kalendertijd: 120 uur is vijf kalenderdagen. K6w, K7w en K8w zijn in
   werkdagen volgens `Werkdagen` (feestdagen van de rijksoverheid, zonder Goede Vrijdag).
   Vrije dagen van een individuele medewerker tellen in beide varianten mee als werktijd.
6. Drempels zijn voorstellen tot vaststelling met de leidinggevende.

## Wijzigingslog

| Datum | Versie | Wijziging |
| --- | --- | --- |
| 2026-10-08 | v1 | Eerste versie. K7 telt alleen beantwoorde mails in de teller. Peildatum vervangt DateTime.LocalNow in Doorlooptijd. |
| 2026-10-08 | v1 | Correcties na review, nog voor de nulmeting. Daarom geen nieuwe versie: er is nog niet met v1 gemeten. `Mail`: richting op de bovenste map (de oude zoektekst "sent" trof ook mappen als "Presentaties"), concepten en ongewenste mail vallen weg, vaste volgorde bij gelijke prioriteit (Prioriteit, Categorie, Trefwoord), zaaknummer stopt bij het eerste ongeldige teken, ISO weeknummer. `Doorlooptijd`: antwoord per inkomende mail in plaats van per gesprek, geen koppeling op leeg gespreksonderwerp. `KIM`: open op peildatum vereist startdatum op of voor de peildatum. K3 laat Onbekend buiten beschouwing. K11 telt alleen werkdagen. Nieuw: query `Werkdagen` en optionele indicatoren K6w, K7w en K8w. |
