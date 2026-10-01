// Invoercontrole, gedeeld door frontend (gekopieerd in index.html) en Worker.

export const MAX_LENGTE = 2000;

// Patronen die wijzen op persoonsgegevens of zaakinhoud. Bewust ruim.
const PATRONEN = [
  { naam: "zaaknummer", re: /ANVS-[A-Z]{1,4}-?\d{4}[\/-]\d+/i },
  { naam: "e-mailadres", re: /[\w.+-]+@[\w-]+\.[\w.-]+/ },
  { naam: "telefoonnummer", re: /(\+31|0031|\b0)[\s-]?6[\s-]?\d{2}[\s-]?\d{2}[\s-]?\d{2}[\s-]?\d{2}\b|\b0\d{2,3}[\s-]?\d{6,7}\b/ },
  { naam: "kenteken", re: /\b[A-Z]{1,3}-?\d{1,3}-?[A-Z]{1,3}\b|\b\d{1,3}-?[A-Z]{2,3}-?\d{1,3}\b/ },
  { naam: "BSN of vergelijkbaar nummer", re: /\b\d{9}\b/ },
  { naam: "postcode met huisnummer", re: /\b\d{4}\s?[A-Z]{2}\b.{0,12}\b\d{1,4}\b|\b\d{1,4}\b.{0,12}\b\d{4}\s?[A-Z]{2}\b/ },
];

/**
 * Geeft null terug als de vraag door mag, anders een korte reden in het Nederlands.
 */
export function controleerVraag(vraag) {
  if (typeof vraag !== "string") return "De vraag ontbreekt.";
  const tekst = vraag.trim();
  if (tekst.length === 0) return "De vraag is leeg.";
  if (tekst.length > MAX_LENGTE) return `De vraag is langer dan ${MAX_LENGTE} tekens.`;
  for (const p of PATRONEN) {
    if (p.re.test(tekst)) {
      return `De vraag lijkt een ${p.naam} te bevatten. Verwijder persoonsgegevens en zaakgegevens en stel de vraag opnieuw.`;
    }
  }
  return null;
}
