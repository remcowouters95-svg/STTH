// Query: Werkdagen
// Datumtabel met weekenden en feestdagen van de rijksoverheid. Gebruikt voor de doorlooptijd in
// werkdagen (Doorlooptijd) en het filter op werkdagen (UrenPerDag). Kan ook als datumtabel in het model.
// Afhankelijk van: geen
// Startjaar en Eindjaar moeten de meetperiode en de peildatum omvatten.
let
    // ---- instellingen ----
    Startjaar        = 2026,
    Eindjaar         = 2027,
    // Goede Vrijdag is geen vrije dag in de CAO Rijk; zet op true als dat voor het team wel geldt
    GoedeVrijdagVrij = false,
    // -----------------------

    // eerste paasdag volgens het algoritme van Meeus (Gregoriaanse kalender)
    Pasen = (j as number) as date =>
        let
            a     = Number.Mod(j, 19),
            b     = Number.IntegerDivide(j, 100),
            c     = Number.Mod(j, 100),
            d     = Number.IntegerDivide(b, 4),
            e     = Number.Mod(b, 4),
            f     = Number.IntegerDivide(b + 8, 25),
            g     = Number.IntegerDivide(b - f + 1, 3),
            h     = Number.Mod(19 * a + b - d - g + 15, 30),
            i     = Number.IntegerDivide(c, 4),
            k     = Number.Mod(c, 4),
            l     = Number.Mod(32 + 2 * e + 2 * i - h - k, 7),
            m     = Number.IntegerDivide(a + 11 * h + 22 * l, 451),
            maand = Number.IntegerDivide(h + l - 7 * m + 114, 31),
            dag   = Number.Mod(h + l - 7 * m + 114, 31) + 1
        in
            #date(j, maand, dag),

    // feestdagen die op een werkdag vrij zijn; eerste paas- en pinksterdag vallen altijd op zondag
    FeestdagenJaar = (j as number) as list =>
        let
            p          = Pasen(j),
            koningsdag = if Date.DayOfWeek(#date(j, 4, 27), Day.Monday) = 6
                         then #date(j, 4, 26) else #date(j, 4, 27)
        in
            {
                {#date(j, 1, 1),       "Nieuwjaarsdag"},
                {Date.AddDays(p, 1),   "Tweede paasdag"},
                {koningsdag,           "Koningsdag"},
                {#date(j, 5, 5),       "Bevrijdingsdag"},
                {Date.AddDays(p, 39),  "Hemelvaartsdag"},
                {Date.AddDays(p, 50),  "Tweede pinksterdag"},
                {#date(j, 12, 25),     "Eerste kerstdag"},
                {#date(j, 12, 26),     "Tweede kerstdag"}
            }
            & (if GoedeVrijdagVrij then {{Date.AddDays(p, -2), "Goede Vrijdag"}} else {}),

    // ISO weeknummer: de week hoort bij het jaar waarin de donderdag valt
    IsoDonderdag = (d as date) as date => Date.AddDays(d, 3 - Date.DayOfWeek(d, Day.Monday)),

    FeestLijst  = #table(
                      type table [Datum = date, Feestdag = text],
                      List.Combine(List.Transform({Startjaar .. Eindjaar}, FeestdagenJaar))
                  ),
    // Hemelvaartsdag kan op 5 mei vallen; dan een rij per datum met beide namen
    Feestdagen  = Table.Group(
                      FeestLijst, {"Datum"},
                      {{"Feestdag", each Text.Combine([Feestdag], " en "), type text}}
                  ),

    Eerste      = #date(Startjaar, 1, 1),
    Laatste     = #date(Eindjaar, 12, 31),
    Datums      = List.Dates(Eerste, Duration.Days(Laatste - Eerste) + 1, #duration(1, 0, 0, 0)),
    Basis       = Table.FromColumns({Datums}, type table [Datum = date]),

    MetFeest    = Table.NestedJoin(
                      Basis, {"Datum"},
                      Feestdagen, {"Datum"},
                      "F", JoinKind.LeftOuter
                  ),
    Uitgeklapt  = Table.ExpandTableColumn(MetFeest, "F", {"Feestdag"}, {"Feestdag"}),
    Gesorteerd  = Table.Sort(Uitgeklapt, {{"Datum", Order.Ascending}}),

    MetJaar     = Table.AddColumn(Gesorteerd, "Jaar", each Date.Year([Datum]), Int64.Type),
    MetMaand    = Table.AddColumn(MetJaar, "Maand", each Date.Month([Datum]), Int64.Type),
    MetIsoWeek  = Table.AddColumn(
                      MetMaand, "IsoWeek",
                      each Number.IntegerDivide(Date.DayOfYear(IsoDonderdag([Datum])) - 1, 7) + 1,
                      Int64.Type
                  ),
    MetIsoJaar  = Table.AddColumn(
                      MetIsoWeek, "IsoJaar",
                      each Date.Year(IsoDonderdag([Datum])), Int64.Type
                  ),
    MetWeekdag  = Table.AddColumn(
                      MetIsoJaar, "Weekdag",
                      each Date.DayOfWeekName([Datum], "nl-NL"), type text
                  ),
    MetWeekend  = Table.AddColumn(
                      MetWeekdag, "IsWeekend",
                      each Date.DayOfWeek([Datum], Day.Monday) >= 5, type logical
                  ),
    MetWerkdag  = Table.AddColumn(
                      MetWeekend, "IsWerkdag",
                      each not [IsWeekend] and [Feestdag] = null, type logical
                  )
in
    MetWerkdag
