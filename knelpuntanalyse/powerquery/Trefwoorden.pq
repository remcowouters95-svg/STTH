// Query: Trefwoorden  (versie v1)
// Classificatiewoordenboek. Lager getal bij Prioriteit wint als een mail op meerdere woorden scoort.
// Trefwoorden altijd in kleine letters; de zoektekst wordt ook naar kleine letters omgezet.
// Bij elke meting deze tabel exporteren met versienummer; wijzigt hij, dan nulmeting opnieuw berekenen.
let
    Bron = #table(
        type table [
            Categorie  = text,
            Soort      = text,
            Trefwoord  = text,
            Prioriteit = number
        ],
        {
            // --- statusvragen (wint van inhoudelijke categorieen) ---
            {"Statusvraag", "Statusvraag", "stand van zaken", 3},
            {"Statusvraag", "Statusvraag", "nog niets gehoord", 3},
            {"Statusvraag", "Statusvraag", "hoe staat het", 3},
            {"Statusvraag", "Statusvraag", "graag een update", 3},
            {"Statusvraag", "Statusvraag", "wanneer kan ik", 4},

            // --- zeven DDA werkinstructies ---
            {"Beschadigde transportverpakking", "Werkinstructie", "beschadig", 10},
            {"Beschadigde transportverpakking", "Werkinstructie", "transportverpakking", 10},
            {"Beschadigde transportverpakking", "Werkinstructie", "colli", 20},

            {"Vermissing transportverpakking", "Werkinstructie", "vermis", 10},
            {"Vermissing transportverpakking", "Werkinstructie", "zoekgeraakt", 10},
            {"Vermissing transportverpakking", "Werkinstructie", "kwijtgeraakt", 15},

            {"Uitvaart radioactieve stoffen", "Werkinstructie", "uitvaart", 10},
            {"Uitvaart radioactieve stoffen", "Werkinstructie", "crematie", 10},
            {"Uitvaart radioactieve stoffen", "Werkinstructie", "overled", 15},
            {"Uitvaart radioactieve stoffen", "Werkinstructie", "begraf", 15},

            {"Detectie radioactief materiaal", "Werkinstructie", "detectie", 20},
            {"Detectie radioactief materiaal", "Werkinstructie", "poortdetectie", 10},
            {"Detectie radioactief materiaal", "Werkinstructie", "alarmering", 20},

            {"Speciale gevallen schroot", "Werkinstructie", "schroot", 10},
            {"Speciale gevallen schroot", "Werkinstructie", "metaalrecycling", 15},
            {"Speciale gevallen schroot", "Werkinstructie", "smelter", 15},

            {"Detectie Douane", "Werkinstructie", "douane", 12},
            {"Detectie Douane", "Werkinstructie", "container", 25},

            {"Douane postsorteercentra", "Werkinstructie", "postsorteer", 8},
            {"Douane postsorteercentra", "Werkinstructie", "sorteercentrum", 8},
            {"Douane postsorteercentra", "Werkinstructie", "pakket", 25},

            // --- standaard reactieve mailtypes ---
            {"Ontvangstbevestiging", "Standaardmail", "ontvangstbevestiging", 5},
            {"Ontvangstbevestiging", "Standaardmail", "wij hebben uw", 7},
            {"Ontvangstbevestiging", "Standaardmail", "in goede orde ontvangen", 5},

            {"Akkoord op werkzaamheden", "Standaardmail", "akkoord", 7},
            {"Akkoord op werkzaamheden", "Standaardmail", "instemming", 7},
            {"Akkoord op werkzaamheden", "Standaardmail", "geen bezwaar", 7},

            {"Vraag belanghebbende", "Standaardmail", "vraag over", 9},
            {"Vraag belanghebbende", "Standaardmail", "verzoek om informatie", 9},
            {"Vraag belanghebbende", "Standaardmail", "kunt u aangeven", 9},

            // --- overig herkenbaar verkeer ---
            {"Zaaknummer genoemd", "Kenmerk", "anvs-", 30},
            {"Handhaving", "Proces", "handhaving", 18},
            {"Handhaving", "Proces", "last onder dwangsom", 12},
            {"Inspectie", "Proces", "inspectie", 18},
            {"Inspectie", "Proces", "controlebezoek", 12},
            {"Vergunning", "Proces", "vergunning", 18},
            {"Vergunning", "Proces", "kennisgeving", 18}
        }
    )
in
    Bron
