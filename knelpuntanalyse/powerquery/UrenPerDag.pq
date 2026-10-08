// Query: UrenPerDag
// Aantal verschillende klokuren per werkdag waarin mail is verzonden (indicator voor versnippering, K11).
// Afhankelijk van: Mail
let
    Uit      = Table.SelectRows(Mail,
                   each [Richting] = "Uitgaand" and [DateTimeSent] <> null),
    MetDag   = Table.AddColumn(Uit, "Dag",
                   each Date.From([DateTimeSent]), type date),
    MetUur   = Table.AddColumn(MetDag, "UurVerzonden",
                   each Time.Hour(DateTime.Time([DateTimeSent])), Int64.Type),
    PerDag   = Table.Group(MetUur, {"Dag"},
                   {{"UrenMetMail",
                     each List.Count(List.Distinct([UurVerzonden])), Int64.Type}})
in
    PerDag
