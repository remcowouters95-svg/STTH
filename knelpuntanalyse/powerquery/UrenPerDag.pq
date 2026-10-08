// Query: UrenPerDag
// Aantal verschillende klokuren per werkdag waarin mail is verzonden (indicator voor versnippering, K11).
// Weekenden en feestdagen tellen niet mee, zoals de definitie "per werkdag" zegt.
// Afhankelijk van: Mail, Werkdagen
let
    Vrij      = List.Buffer(Table.SelectRows(Werkdagen, each not [IsWerkdag])[Datum]),
    Uit       = Table.SelectRows(Mail,
                    each [Richting] = "Uitgaand" and [DateTimeSent] <> null),
    MetDag    = Table.AddColumn(Uit, "Dag",
                    each Date.From([DateTimeSent]), type date),
    OpWerkdag = Table.SelectRows(MetDag, each not List.Contains(Vrij, [Dag])),
    MetUur    = Table.AddColumn(OpWerkdag, "UurVerzonden",
                    each Time.Hour(DateTime.Time([DateTimeSent])), Int64.Type),
    PerDag    = Table.Group(MetUur, {"Dag"},
                    {{"UrenMetMail",
                      each List.Count(List.Distinct([UurVerzonden])), Int64.Type}})
in
    PerDag
