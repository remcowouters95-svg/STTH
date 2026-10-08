// Query: Mail
// Leest de eigen Outlook mailbox via de Exchange connector, voegt zaaknummer en categorie toe.
// Afhankelijk van: Trefwoorden
// Pas Adres, Startdatum en Einddatum aan. Alleen lezen: er wordt niets in Outlook gewijzigd.
let
    // ---- instellingen ----
    Adres        = "voornaam.achternaam@anvs.nl",
    Startdatum   = #date(2026, 4, 1),
    Einddatum    = #date(2026, 9, 30),
    EigenDomein  = "anvs.nl",
    // bovenste map (kleine letters) die als uitgaand telt, en mappen die niet meetellen
    MappenUit    = {"verzonden items", "sent items"},
    MappenNiet   = {"concepten", "drafts", "postvak uit", "outbox",
                    "ongewenste e-mail", "junk e-mail", "junk email",
                    "synchronisatieproblemen", "sync issues"},
    // -----------------------

    Bron         = Exchange.Contents(Adres),
    MailTabel    = Bron{[Name = "Mail"]}[Data],

    // sommige versies van de connector zetten ConversationTopic en DateTimeSent in de kolom
    // Attributes in plaats van als eigen kolom; haal ze daar dan uit
    UitAttribuut = List.Difference({"ConversationTopic", "DateTimeSent"}, Table.ColumnNames(MailTabel)),
    MetAttribuut = if Table.HasColumns(MailTabel, "Attributes") and not List.IsEmpty(UitAttribuut)
                   then Table.ExpandRecordColumn(MailTabel, "Attributes", UitAttribuut, UitAttribuut)
                   else MailTabel,

    Kolommen     = Table.SelectColumns(
                        MetAttribuut,
                        {
                            "Id", "Folder Path", "Subject", "Body",
                            "DateTimeReceived", "DateTimeSent",
                            "Sender", "ToRecipients", "IsRead",
                            "HasAttachments", "Attachments",
                            "ConversationTopic", "Categories"
                        },
                        MissingField.Ignore
                   ),

    // tijden als lokale datetime, ook als de connector datetimezone levert
    NaarLokaal   = (x) => if x is datetimezone
                          then DateTimeZone.RemoveZone(DateTimeZone.ToLocal(x))
                          else x,
    Tijden       = Table.TransformColumns(
                        Kolommen,
                        {
                            {"DateTimeReceived", NaarLokaal, type datetime},
                            {"DateTimeSent", NaarLokaal, type datetime}
                        },
                        null,
                        MissingField.Ignore
                   ),

    // vast meetvenster, nooit "tot vandaag"
    OpDatum      = Table.SelectRows(
                        Tijden,
                        each [DateTimeReceived] >= DateTime.From(Startdatum)
                         and [DateTimeReceived] <  DateTime.From(Date.AddDays(Einddatum, 1))
                   ),

    // bovenste map van het pad, bijvoorbeeld "\Verzonden items\Project\" wordt "verzonden items"
    MetMap       = Table.AddColumn(
                        OpDatum, "Map",
                        each Text.Lower(Text.Trim(
                            List.First(
                                List.Select(Text.Split([Folder Path] ?? "", "\"), (s) => s <> ""),
                                ""))),
                        type text
                   ),
    ZonderNiet   = Table.SelectRows(MetMap, each not List.Contains(MappenNiet, [Map])),

    AfzenderUit  = Table.ExpandRecordColumn(
                        ZonderNiet, "Sender",
                        {"Name", "Address"},
                        {"AfzenderNaam", "AfzenderAdres"}
                   ),

    MetDomein    = Table.AddColumn(
                        AfzenderUit, "AfzenderDomein",
                        each try Text.Lower(Text.AfterDelimiter([AfzenderAdres], "@"))
                             otherwise null,
                        type text
                   ),

    MetIntern    = Table.AddColumn(
                        MetDomein, "Intern",
                        each [AfzenderDomein] = EigenDomein,
                        type logical
                   ),

    MetRichting  = Table.AddColumn(
                        MetIntern, "Richting",
                        each if List.Contains(MappenUit, [Map]) then "Uitgaand" else "Inkomend",
                        type text
                   ),

    // onderwerp zonder RE, FW, ANTW enzovoort
    SchoonOnderw = Table.AddColumn(
                        MetRichting, "OnderwerpSchoon",
                        each Text.Trim(
                            Text.Combine(
                                List.Select(
                                    Text.Split(Text.Clean([Subject] ?? ""), " "),
                                    each not List.Contains(
                                        {"re:", "fw:", "fwd:", "antw:", "aw:",
                                         "doorst:", "re", "fw"},
                                        Text.Lower(_))
                                ), " ")),
                        type text
                   ),

    MetDatum     = Table.AddColumn(
                        SchoonOnderw, "Datum",
                        each Date.From([DateTimeReceived]), type date
                   ),
    // ISO weeknummer zoals in Nederland gebruikelijk (week van de donderdag)
    MetWeek      = Table.AddColumn(
                        MetDatum, "Weeknummer",
                        each Number.IntegerDivide(
                            Date.DayOfYear(
                                Date.AddDays([Datum], 3 - Date.DayOfWeek([Datum], Day.Monday))
                            ) - 1, 7) + 1,
                        Int64.Type
                   ),
    MetUur       = Table.AddColumn(
                        MetWeek, "Uur",
                        each Time.Hour(DateTime.Time([DateTimeReceived])),
                        Int64.Type
                   ),

    MetBijlagen  = Table.AddColumn(
                        MetUur, "AantalBijlagen",
                        each try Table.RowCount([Attachments]) otherwise 0,
                        Int64.Type
                   ),

    Opgeschoond  = Table.RemoveColumns(MetBijlagen, {"Attachments"}, MissingField.Ignore),

    // eerste geldige zaaknummer van de vorm ANVS-XX-JJJJ/NNNNNNN in onderwerp of begin body;
    // het nummer stopt bij het eerste teken dat geen letter, cijfer, - of / is
    Toegestaan   = {"A" .. "Z", "0" .. "9", "-", "/"},
    MetZaaknr    = Table.AddColumn(
                        Opgeschoond, "Zaaknummer",
                        each let
                            t          = Text.Upper(([Subject] ?? "") & " " & Text.Start([Body] ?? "", 3000)),
                            posities   = Text.PositionOf(t, "ANVS-", Occurrence.All),
                            kandidaten = List.Transform(
                                             posities,
                                             (p) => Text.Combine(
                                                 List.FirstN(
                                                     Text.ToList(Text.Middle(t, p, 30)),
                                                     (c) => List.Contains(Toegestaan, c)))),
                            geldig     = List.Select(kandidaten, (k) => Text.Contains(k, "/"))
                        in
                            List.First(geldig, null),
                        type text
                   ),

    // classificatie op onderwerp plus eerste 1500 tekens body
    Zoekveld     = Table.AddColumn(
                        MetZaaknr, "Zoektekst",
                        each Text.Lower(
                            Text.Combine({
                                [Subject] ?? "",
                                Text.Start([Body] ?? "", 1500)
                            }, " ")),
                        type text
                   ),

    // trefwoorden een keer in het geheugen in plaats van per mail opnieuw
    TrefBuffer   = Table.Buffer(Trefwoorden),

    MetTreffers  = Table.AddColumn(
                        Zoekveld, "Treffers",
                        each Table.SelectRows(
                            TrefBuffer,
                            (t) => Text.Contains([Zoektekst], t[Trefwoord])
                        ),
                        type table
                   ),

    // bij gelijke prioriteit beslissen Categorie en Trefwoord, zodat de uitkomst vastligt
    MetBeste     = Table.AddColumn(
                        MetTreffers, "Beste",
                        each if Table.RowCount([Treffers]) = 0 then null
                             else Table.Sort(
                                 [Treffers],
                                 {{"Prioriteit", Order.Ascending},
                                  {"Categorie", Order.Ascending},
                                  {"Trefwoord", Order.Ascending}}){0},
                        type record
                   ),

    MetCategorie = Table.AddColumn(
                        MetBeste, "Categorie",
                        each if [Beste] = null then "Onbekend" else [Beste][Categorie],
                        type text
                   ),

    MetSoort     = Table.AddColumn(
                        MetCategorie, "Soort",
                        each if [Beste] = null then "Onbekend" else [Beste][Soort],
                        type text
                   ),

    MetScore     = Table.AddColumn(
                        MetSoort, "AantalTreffers",
                        each Table.RowCount([Treffers]), Int64.Type
                   ),

    // Body verwijderen houdt het model licht en beperkt persoonsgegevens in het .pbix
    Eindresultaat = Table.RemoveColumns(
                        MetScore,
                        {"Treffers", "Beste", "Zoektekst", "Body"}
                   )
in
    Eindresultaat
