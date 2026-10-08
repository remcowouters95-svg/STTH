// Query: Streeftermijnen
// Termijn in kalenderdagen per zaaktype zoals die in het team geldt.
// Zaaktypen moeten exact gelijk zijn aan de kolom Zaaktype in de KIM export.
let
    Bron = #table(
        type table [Zaaktype = text, StreeftermijnDagen = number],
        {
            {"Vul zaaktype in", 56},
            {"Vul zaaktype in 2", 28}
        }
    )
in
    Bron
