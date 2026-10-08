// Query: Doorlooptijd
// Koppelt inkomende mail aan het eerste uitgaande antwoord in hetzelfde gesprek (ConversationTopic).
// Meet reactietijd per gesprek in kalenderuren, niet per zaak en niet in werkdagen.
// Afhankelijk van: Mail
let
    // ---- instellingen ----
    // einde meetperiode; gelijk houden aan Einddatum in Mail zodat K8 reproduceerbaar is
    Peildatum   = #datetime(2026, 9, 30, 23, 59, 59),
    // -----------------------

    Bron        = Mail,

    Inkomend    = Table.SelectRows(Bron, each [Richting] = "Inkomend"),
    Uitgaand    = Table.SelectRows(Bron, each [Richting] = "Uitgaand"),

    AntwoordPer = Table.Group(
                      Uitgaand, {"ConversationTopic"},
                      {{"EersteAntwoord", each List.Min([DateTimeSent]), type datetime}}
                  ),

    Gekoppeld   = Table.NestedJoin(
                      Inkomend, {"ConversationTopic"},
                      AntwoordPer, {"ConversationTopic"},
                      "A", JoinKind.LeftOuter
                  ),
    Uitgeklapt  = Table.ExpandTableColumn(
                      Gekoppeld, "A", {"EersteAntwoord"}, {"EersteAntwoord"}
                  ),

    // alleen antwoorden na binnenkomst en voor de peildatum tellen
    Geldig      = Table.AddColumn(
                      Uitgeklapt, "AntwoordDatum",
                      each if [EersteAntwoord] <> null
                              and [EersteAntwoord] > [DateTimeReceived]
                              and [EersteAntwoord] <= Peildatum
                           then [EersteAntwoord] else null,
                      type datetime
                  ),

    MetUren     = Table.AddColumn(
                      Geldig, "DoorlooptijdUren",
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
                  )
in
    MetLeeftijd
