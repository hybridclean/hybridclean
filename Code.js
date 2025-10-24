function processLogin(user) {
  Logger.log(`processLogin(): Benutzer "${user}" angemeldet.`);
  if (!user) {
    return { success: false, message: "Ungültiger Benutzername." };
  }

  // Geräteart erkennen (Client sendet sie mit)
  const device = (typeof Session !== 'undefined' && Session.getActiveUser()) ? "Desktop" : "Mobile";
  logEvent(user, "Login", device);

  const url = ScriptApp.getService().getUrl();
  const redirect = `${url}?user=${encodeURIComponent(user)}`;
  return { success: true, redirect };
}


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

/******************************************************
 * 🚪 Logout-Funktion mit Datenlöschung + Logging
 ******************************************************/
/******************************************************
 * 🚪 Logout: löscht alle Userdaten + leitet zurück
 ******************************************************/
function logoutUser(user) {
  try {
    PropertiesService.getUserProperties().deleteAllProperties();
    logEvent(user || "Unbekannt", "Logout", "");
  } catch (err) {
    console.error("Fehler beim Logout:", err);
  }

  const url = ScriptApp.getService().getUrl();
  return HtmlService.createHtmlOutput(
    `<script>
       console.log("Logout ausgeführt – zurück zur Loginseite");
       window.top.location.replace('${url}?logout=true');
     </script>`
  );
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
/******************************************************
 * 🪵 Server Logging in Tabellenblatt "Logs"
 ******************************************************/
function logEvent(user, action, device) {
  try {
    const ss = SpreadsheetApp.openById(CONFIG.SHEET_ID);
    let sheet = ss.getSheetByName("Logs");
    if (!sheet) sheet = ss.insertSheet("Logs");

    const ts = new Date();
    sheet.appendRow([ts, user, action, device || "unbekannt"]);
  } catch (err) {
    console.error("Fehler beim Loggen:", err);
  }
}

// ⬇️ doGet minimal ergänzen (ganz oben in doGet hinzufügen):
// if (e && e.parameter && e.parameter.diag === '1') return diagJson();
