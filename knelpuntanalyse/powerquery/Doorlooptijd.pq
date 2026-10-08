// Query: Doorlooptijd
// Koppelt elke inkomende mail aan het eerste uitgaande antwoord daarna in hetzelfde gesprek
// (ConversationTopic). Meet reactietijd per gesprek, niet per zaak.
// Twee maten naast elkaar: kalenderuren (K6, K7, K8) en werkdagen (K6w, K7w, K8w).
// Afhankelijk van: Mail, Werkdagen
let
    // ---- instellingen ----
    // einde meetperiode; gelijk houden aan Einddatum in Mail zodat K8 reproduceerbaar is
    Peildatum   = #datetime(2026, 9, 30, 23, 59, 59),
    // -----------------------

    Bron        = Mail,

    Inkomend    = Table.SelectRows(Bron, each [Richting] = "Inkomend"),
    // zonder gespreksonderwerp is er geen koppeling; anders zouden alle lege onderwerpen aan elkaar hangen
    Uitgaand    = Table.SelectRows(
                      Bron,
                      each [Richting] = "Uitgaand"
                       and [DateTimeSent] <> null
                       and [ConversationTopic] <> null
                       and [ConversationTopic] <> ""
                  ),

    AntwoordPer = Table.Group(
                      Uitgaand, {"ConversationTopic"},
                      {{"Antwoorden", each List.Sort([DateTimeSent]), type list}}
                  ),

    Gekoppeld   = Table.NestedJoin(
                      Inkomend, {"ConversationTopic"},
                      AntwoordPer, {"ConversationTopic"},
                      "A", JoinKind.LeftOuter
                  ),
    Uitgeklapt  = Table.ExpandTableColumn(
                      Gekoppeld, "A", {"Antwoorden"}, {"Antwoorden"}
                  ),

    // eerste antwoord na binnenkomst van deze mail en uiterlijk op de peildatum;
    // een tweede vraag in hetzelfde gesprek krijgt zo zijn eigen antwoord
    Geldig      = Table.AddColumn(
                      Uitgeklapt, "AntwoordDatum",
                      each List.Min(
                          List.Select(
                              [Antwoorden] ?? {},
                              (a) => a > [DateTimeReceived] and a <= Peildatum)),
                      type datetime
                  ),
    ZonderLijst = Table.RemoveColumns(Geldig, {"Antwoorden"}),

    MetUren     = Table.AddColumn(
                      ZonderLijst, "DoorlooptijdUren",
                      each if [AntwoordDatum] = null then null
                           else Duration.TotalHours([AntwoordDatum] - [DateTimeReceived]),
                      type number
                  ),

    MetStatus   = Table.AddColumn(
                      MetUren, "Status",
                      each if [AntwoordDatum] <> null then "Beantwoord" else "Open",
                      type text
                  ),

    MetLeeftijd = Table.AddColumn(
                      MetStatus, "LeeftijdDagen",
                      each if [Status] = "Open"
                           then Duration.TotalDays(Peildatum - [DateTimeReceived])
                           else null,
                      type number
                  ),

    // ---- werkdagen ----
    // Een werkdag telt volledig mee (24 uur); alleen tijd in weekenden en op feestdagen valt weg.
    // Voorbeeld: vrijdag 16.00 binnen, maandag 10.00 beantwoord is 0,75 werkdag.
    Feestdagen  = List.Buffer(Table.SelectRows(Werkdagen, each [Feestdag] <> null)[Datum]),
    IsVrij      = (d as date) as logical =>
                      Date.DayOfWeek(d, Day.Monday) >= 5 or List.Contains(Feestdagen, d),
    Werkdagtijd = (van as datetime, tot as datetime) as number =>
                      if tot <= van then 0
                      else
                          let
                              dagen = List.Dates(
                                          Date.From(van),
                                          Duration.Days(Date.From(tot) - Date.From(van)) + 1,
                                          #duration(1, 0, 0, 0)),
                              uren  = List.Transform(
                                          List.Select(dagen, (d) => not IsVrij(d)),
                                          (d) => Duration.TotalHours(
                                              List.Min({tot, Date.AddDays(d, 1) & #time(0, 0, 0)})
                                              - List.Max({van, d & #time(0, 0, 0)})))
                          in
                              (List.Sum(uren) ?? 0) / 24,

    MetWerkdagen = Table.AddColumn(
                      MetLeeftijd, "DoorlooptijdWerkdagen",
                      each if [AntwoordDatum] = null then null
                           else Werkdagtijd([DateTimeReceived], [AntwoordDatum]),
                      type number
                  ),

    MetLeeftijdW = Table.AddColumn(
                      MetWerkdagen, "LeeftijdWerkdagen",
                      each if [Status] = "Open"
                           then Werkdagtijd([DateTimeReceived], Peildatum)
                           else null,
                      type number
                  )
in
    MetLeeftijdW
