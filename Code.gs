

/******************************************************
 * 🚀 Einstiegspunkt – doGet()
 ******************************************************/
function doGet(e) {
  if (e && e.parameter && e.parameter.diag === '1') return diagJson();
  const props = PropertiesService.getUserProperties();

  if (e && e.parameter.logout === 'true') props.deleteAllProperties();

  const user = props.getProperty('CURRENT_USER');
  const schausteller = props.getProperty('CURRENT_SCHAUSTELLER');

  // kein Login vorhanden → Loginseite
  if (!user || !schausteller) {
    return HtmlService.createTemplateFromFile('index')
      .evaluate()
      .setTitle(CONFIG.APP_NAME + ' – Anmeldung')
      .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
  }

  // eingeloggt → Datenpflege
  const t = HtmlService.createTemplateFromFile('User_DataMaintenance');
  t.user = user;
  t.schausteller = schausteller;
  return t.evaluate()
    .setTitle(CONFIG.APP_NAME + ' – Datenpflege')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

/******************************************************
 * 🔐 Login / Logout
 ******************************************************/
function processLogin(data) {
  const props = PropertiesService.getUserProperties();
  props.setProperty('CURRENT_USER', data.name);
  props.setProperty('CURRENT_SCHAUSTELLER', data.schausteller);
  return true;
}

function logoutUser() {
  PropertiesService.getUserProperties().deleteAllProperties();
  return true;
}

/******************************************************
 * 🎪 Schaustellerliste laden
 ******************************************************/
function getSchaustellerList() {
  const sheet = SpreadsheetApp.openById(CONFIG.SHEET_ID)
    .getSheetByName(CONFIG.SHEET_SCHAUSTELLER);
  if (!sheet) return [];
  const values = sheet.getRange('A2:A' + sheet.getLastRow()).getValues();
  return values.flat().filter(String);
}

/******************************************************
 * 📊 Beispiel: Datensatz lesen
 ******************************************************/
function getData() {
  const sh = SpreadsheetApp.openById(CONFIG.SHEET_ID).getSheets()[0];
  const v = sh.getDataRange().getValues();
  const headers = v.shift();
  return v.map(r => Object.fromEntries(headers.map((h, i) => [h, r[i]])));
}

/******************************************************
 * 🧩 HTML include helper
 ******************************************************/
function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}
// ⬇️ Add-on: Diagnose-Endpoint
function diagJson() {
  const res = {
    scriptId: ScriptApp.getScriptId(),
    appName: CONFIG.APP_NAME,
    sheetId: CONFIG.SHEET_ID,
    hasSheet_Schausteller: false,
    schaustellerCount: 0,
    userProps: PropertiesService.getUserProperties().getProperties(),
    serverTime: new Date().toISOString(),
  };
  try {
    const sh = SpreadsheetApp.openById(CONFIG.SHEET_ID).getSheetByName(CONFIG.SHEET_SCHAUSTELLER || 'Schausteller');
    if (sh) {
      res.hasSheet_Schausteller = true;
      const vals = sh.getRange(2,1,Math.max(sh.getLastRow()-1,0),1).getValues().flat().filter(String);
      res.schaustellerCount = vals.length;
    }
  } catch (e) {
    res.error = String(e);
  }
  return ContentService
    .createTextOutput(JSON.stringify(res, null, 2))
    .setMimeType(ContentService.MimeType.JSON);
}

// ⬇️ doGet minimal ergänzen (ganz oben in doGet hinzufügen):
// if (e && e.parameter && e.parameter.diag === '1') return diagJson();
