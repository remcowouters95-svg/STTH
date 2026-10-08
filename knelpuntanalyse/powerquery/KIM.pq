// Query: KIM
// Leest een Excel export per zaak uit KIM. Kolomnamen zijn aannames; pas ze aan aan de echte export.
// De peildatum is het einde van de meetperiode, niet vandaag, zodat de meting reproduceerbaar is.
// Afhankelijk van: Streeftermijnen
let
    // ---- instellingen ----
    Pad        = "H:\Analyse\KIM_export.xlsx",
    Peildatum  = #date(2026, 9, 30),
    // -----------------------

    Bron       = Excel.Workbook(File.Contents(Pad), true),
    // eerste werkblad; Bron{0} kan ook een tabel of benoemd bereik zijn
    Blad       = Table.SelectRows(Bron, each [Kind] = "Sheet"){0}[Data],
    Kolommen   = Table.SelectColumns(
                     Blad,
                     {"Zaaknummer", "Zaaktype", "Status",
                      "Startdatum", "Einddatum", "Behandelaar"},
                     MissingField.Ignore),
    Typen      = Table.TransformColumnTypes(
                     Kolommen,
                     {{"Startdatum", type date}, {"Einddatum", type date}}),
    // zelfde schrijfwijze als Mail[Zaaknummer]; ook als Excel een getal of leeg veld levert
    Genormd    = Table.TransformColumns(
                     Typen,
                     {{"Zaaknummer", each if _ = null then null else Text.Upper(Text.Trim(Text.From(_))), type text},
                      {"Zaaktype", each if _ = null then null else Text.Trim(Text.From(_)), type text}}),

    // open op de peildatum: gestart op of voor de peildatum en toen nog niet afgesloten
    MetOpen    = Table.AddColumn(
                     Genormd, "OpenOpPeildatum",
                     each [Startdatum] <> null
                          and [Startdatum] <= Peildatum
                          and ([Einddatum] = null or [Einddatum] > Peildatum),
                     type logical),
    MetLeeftijd = Table.AddColumn(
                     MetOpen, "LeeftijdDagen",
                     each try Duration.Days(
                         (if [OpenOpPeildatum] then Peildatum else [Einddatum])
                         - [Startdatum]) otherwise null,
                     Int64.Type),

    MetTermijn = Table.NestedJoin(
                     MetLeeftijd, {"Zaaktype"},
                     Streeftermijnen, {"Zaaktype"},
                     "T", JoinKind.LeftOuter),
    Uitgeklapt = Table.ExpandTableColumn(
                     MetTermijn, "T", {"StreeftermijnDagen"}),

    MetOver    = Table.AddColumn(
                     Uitgeklapt, "OverTermijn",
                     each [OpenOpPeildatum]
                          and [StreeftermijnDagen] <> null
                          and [LeeftijdDagen] <> null
                          and [LeeftijdDagen] > [StreeftermijnDagen],
                     type logical)
in
    MetOver
