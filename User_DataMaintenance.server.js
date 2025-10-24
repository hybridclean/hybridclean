/****************************************************
 * 📂 USER_DATAMAINTENANCE.SERVER.GS
 * --------------------------------------------------
 * Hauptmodul für die Datenpflege in der HybridSheetApp.
 * - Verwaltet Popup-Aufrufe (Auswahl + Bearbeitung)
 * - Lädt Daten aus dem Tabellenblatt "Veranstaltungen"
 * - Steuert Übergabe an Formulare und Rücksprung
 * - Unterstützt später Brieffunktionen & PDF-Erzeugung
 * --------------------------------------------------
 * Stand: 22.10.2025
 ****************************************************/

// === Globale Konstante ===
const SHEET_VERANSTALTUNGEN = "Veranstaltungen";

/****************************************************
 * 🧭 HAUPTFUNKTIONEN – Popup-Steuerung
 ****************************************************/

/**
 * Öffnet das Datenauswahl-Fenster (User_Picker.html)
 */
function openUserPicker() {
  const html = HtmlService.createTemplateFromFile('User_Picker')
    .evaluate()
    .setWidth(1000)
    .setHeight(700)
    .setTitle("🎪 Datensatz auswählen");
  SpreadsheetApp.getUi().showModalDialog(html, "Datensatz auswählen");
}

/**
 * Öffnet das Bearbeitungsformular für den gewählten Datensatz (User_AdressForm.html)
 * @param {string|number} recordId - Eindeutige ID oder Zeilennummer des Datensatzes
 */
function openAdressForm(recordId) {
  const t = HtmlService.createTemplateFromFile('User_AdressForm');
  t.recordId = recordId;
  const html = t.evaluate()
    .setWidth(900)
    .setHeight(650)
    .setTitle("📇 Datensatz bearbeiten");
  SpreadsheetApp.getUi().showModalDialog(html, "Datensatz bearbeiten");
}

/**
 * Schließt die aktuelle Sitzung (zurück zur Loginseite)
 */
function logoutUser() {
  return true; // Logik für Rückkehr wird im Client ausgeführt
}

/****************************************************
 * 📊 DATENABFRAGEN
 ****************************************************/

/**
 * Liest alle Datensätze aus dem Tabellenblatt "Veranstaltungen"
 * Gibt eine Liste von Objekten mit den Spaltenüberschriften als Schlüssel zurück.
 */
function getVeranstaltungen() {
  const ss = SpreadsheetApp.openById(CONFIG.SHEET_ID);
  const sh = ss.getSheetByName(SHEET_VERANSTALTUNGEN);
  if (!sh) throw new Error(`Tabellenblatt "${SHEET_VERANSTALTUNGEN}" nicht gefunden.`);

  const values = sh.getDataRange().getValues();
  const headers = values.shift();

  return values.map(row => {
    const obj = {};
    headers.forEach((h, i) => {
      if (h) obj[h] = row[i];
    });
    return obj;
  });
}

/****************************************************
 * 💾 DATENSATZ SPEICHERN / AKTUALISIEREN
 ****************************************************/

/**
 * Aktualisiert einen bestehenden Datensatz in der Tabelle "Veranstaltungen".
 * @param {Object} record - Schlüssel-Wert-Paar mit den Spaltenüberschriften als Keys.
 */
function saveVeranstaltung(record) {
  const ss = SpreadsheetApp.openById(CONFIG.SHEET_ID);
  const sh = ss.getSheetByName(SHEET_VERANSTALTUNGEN);
  const values = sh.getDataRange().getValues();
  const headers = values.shift();

  const idIndex = headers.indexOf("ID");
  if (idIndex === -1) throw new Error("Spalte 'ID' nicht gefunden.");

  const rowIndex = values.findIndex(r => String(r[idIndex]) === String(record.ID));
  if (rowIndex === -1) throw new Error("Datensatz nicht gefunden.");

  headers.forEach((header, i) => {
    if (record[header] !== undefined) {
      sh.getRange(rowIndex + 2, i + 1).setValue(record[header]);
    }
  });
  return { ok: true, msg: "Datensatz gespeichert." };
}

/****************************************************
 * 📨 BRIEFE & PDFS (Integration)
 ****************************************************/

/**
 * Öffnet das Brief-Formular für die ausgewählte Veranstaltung.
 */
function openLetterForm(recordId) {
  const t = HtmlService.createTemplateFromFile('Letters_Form');
  t.recordId = recordId;
  const html = t.evaluate()
    .setWidth(900)
    .setHeight(700)
    .setTitle("📨 Brief erstellen");
  SpreadsheetApp.getUi().showModalDialog(html, "Brief erstellen");
}

/**
 * Erstellt ein Admin-PDF oder Report für eine Veranstaltung.
 */
function generateAdminPDF(recordId) {
  try {
    const result = createAdminPDF(recordId); // in Letters_AdminPDFs.server_js
    return result || "PDF erfolgreich erstellt.";
  } catch (err) {
    return "Fehler bei PDF-Erstellung: " + err.message;
  }
}

/****************************************************
 * 🧩 HILFSFUNKTIONEN
 ****************************************************/

/**
 * Liest eine einzelne Veranstaltung anhand ihrer ID.
 */
function getVeranstaltungById(id) {
  const ss = SpreadsheetApp.openById(CONFIG.SHEET_ID);
  const sh = ss.getSheetByName(SHEET_VERANSTALTUNGEN);
  const values = sh.getDataRange().getValues();
  const headers = values.shift();

  const idIndex = headers.indexOf("ID");
  if (idIndex === -1) return null;

  const row = values.find(r => String(r[idIndex]) === String(id));
  if (!row) return null;

  const obj = {};
  headers.forEach((h, i) => obj[h] = row[i]);
  return obj;
}
