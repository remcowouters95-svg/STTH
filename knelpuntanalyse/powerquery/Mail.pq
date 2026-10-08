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
    // -----------------------

    Bron         = Exchange.Contents(Adres),
    MailTabel    = Bron{[Name = "Mail"]}[Data],

    // vast meetvenster, nooit "tot vandaag"
    OpDatum      = Table.SelectRows(
                        MailTabel,
                        each [DateTimeReceived] >= DateTime.From(Startdatum)
                         and [DateTimeReceived] <  DateTime.From(Date.AddDays(Einddatum, 1))
                   ),

    Kolommen     = Table.SelectColumns(
                        OpDatum,
                        {
                            "Id", "Folder Path", "Subject", "Body",
                            "DateTimeReceived", "DateTimeSent",
                            "Sender", "ToRecipients", "IsRead",
                            "HasAttachments", "Attachments",
                            "ConversationTopic", "Categories"
                        },
                        MissingField.Ignore
                   ),

    AfzenderUit  = Table.ExpandRecordColumn(
                        Kolommen, "Sender",
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
                        each if Text.Contains(Text.Lower([Folder Path] ?? ""), "verzonden")
                             or Text.Contains(Text.Lower([Folder Path] ?? ""), "sent")
                             then "Uitgaand" else "Inkomend",
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
    MetWeek      = Table.AddColumn(
                        MetDatum, "Weeknummer",
                        each Date.WeekOfYear([Datum]), Int64.Type
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

    // eerste zaaknummer van de vorm ANVS-XX-JJJJ/NNNNNNN in onderwerp of begin body
    MetZaaknr    = Table.AddColumn(
                        Opgeschoond, "Zaaknummer",
                        each let
                            t   = Text.Upper(([Subject] ?? "") & " " & Text.Start([Body] ?? "", 3000)),
                            pos = Text.PositionOf(t, "ANVS-")
                        in
                            if pos < 0 then null
                            else Text.Trim(
                                Text.Split(
                                    Text.Select(Text.Middle(t, pos, 30),
                                        {"A".."Z", "0".."9", "-", "/", " "}),
                                    " "){0}),
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

    MetTreffers  = Table.AddColumn(
                        Zoekveld, "Treffers",
                        each Table.SelectRows(
                            Trefwoorden,
                            (t) => Text.Contains([Zoektekst], t[Trefwoord])
                        ),
                        type table
                   ),

    MetBeste     = Table.AddColumn(
                        MetTreffers, "Beste",
                        each if Table.RowCount([Treffers]) = 0 then null
                             else Table.Sort([Treffers], {{"Prioriteit", Order.Ascending}}){0},
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
