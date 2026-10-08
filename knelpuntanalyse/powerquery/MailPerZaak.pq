// Query: MailPerZaak
// Telt per zaak het mailverkeer, het aantal statusvragen en de langste periode zonder bericht.
// Afhankelijk van: Mail. Koppel in het model aan KIM op Zaaknummer.
let
    Bron       = Table.SelectRows(Mail, each [Zaaknummer] <> null),
    MetTijd    = Table.AddColumn(
                     Bron, "Tijdstip",
                     each if [Richting] = "Uitgaand" and [DateTimeSent] <> null
                          then [DateTimeSent] else [DateTimeReceived],
                     type datetime),
    PerZaak    = Table.Group(
                     MetTijd, {"Zaaknummer"},
                     {
                       {"AantalMails", each Table.RowCount(_), Int64.Type},
                       {"AantalInkomend",
                        each List.Count(List.Select([Richting], each _ = "Inkomend")),
                        Int64.Type},
                       {"AantalStatusvragen",
                        each List.Count(List.Select([Categorie], each _ = "Statusvraag")),
                        Int64.Type},
                       {"LangsteStilteDagen",
                        each let d = List.Sort(List.RemoveNulls([Tijdstip]))
                             in if List.Count(d) < 2 then null
                                else List.Max(List.Transform(
                                    {1 .. List.Count(d) - 1},
                                    (i) => Duration.TotalDays(d{i} - d{i - 1}))),
                        type number},
                       {"EersteMail", each List.Min([Tijdstip]), type datetime},
                       {"LaatsteMail", each List.Max([Tijdstip]), type datetime}
                     })
in
    PerZaak
