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
    Blad       = Bron{0}[Data],
    Kolommen   = Table.SelectColumns(
                     Blad,
                     {"Zaaknummer", "Zaaktype", "Status",
                      "Startdatum", "Einddatum", "Behandelaar"},
                     MissingField.Ignore),
    Typen      = Table.TransformColumnTypes(
                     Kolommen,
                     {{"Startdatum", type date}, {"Einddatum", type date}}),
    Genormd    = Table.TransformColumns(
                     Typen,
                     {{"Zaaknummer", each Text.Upper(Text.Trim(_)), type text}}),

    MetOpen    = Table.AddColumn(
                     Genormd, "OpenOpPeildatum",
                     each [Einddatum] = null or [Einddatum] > Peildatum,
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
