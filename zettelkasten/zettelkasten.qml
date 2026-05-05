// Zettelkasten support for QOwnNotes.
// Actions:
//   • Insert ZK ID    — inserts an ID built from a configurable format string
//   • Insert ZK link  — filters notes by name, picks one, inserts [[filename|ID]]
//   • Repair ZK links — scans all notes and fixes [[oldName|ID]] → [[newName|ID]]
// ID format tokens:  %Y year  %M month  %D day  %h hour  %m minute  %s second
// Example format:    id%Y%M%Dx%h%m%s  →  id20260430x143012
// IDs are detected via a configurable ECMAScript regex (default: \d{14}).
// The regex is tested first against the note filename, then full content —
// first match only.
// Link format:  [[nom_fichier_sur_disque.md|20260430143012]]
// QOwnNotes resolves the filename part as a wiki-link (Ctrl+click to open).
// Rename resilience: when a note carrying a ZK ID is opened, any backlinks in
// other notes that still reference its old filename are silently rewritten to
// use the current filename.  A manual "Repair ZK links" action (ZK-Fix toolbar
// button) performs the same scan across the entire vault in one pass.
import QtQml 2.0
import QOwnNotesTypes 1.0

Script {
    property string idRegex
    property string idFormat
    property bool autoRepairLinks: true

    property variant settingsVariables: [
        {
            "identifier": "idFormat",
            "name": "ID generation format",
            "description": "Format string for generating new IDs.\nTokens: %Y=year  %M=month  %D=day  %h=hour  %m=minute  %s=second\nLiteral characters are kept as-is.\n\nExamples:\n  %Y%M%D%h%m%s        →  20260430143012\n  id%Y%M%Dx%h%m%s     →  id20260430x143012\n  %Y-%M-%D            →  2026-04-30",
            "type": "string",
            "default": "%Y%M%D%h%m%s"
        },
        {
            "identifier": "idRegex",
            "name": "ID detection pattern (ECMAScript regex)",
            "description": "Pattern used to detect Zettelkasten IDs in note filenames and content.\nDefault matches 14-digit timestamps: \\d{14}",
            "type": "string",
            "default": "\\d{14}"
        },
        {
            "identifier": "autoRepairLinks",
            "name": "Auto-repair backlinks on note open",
            "description": "When a note with a ZK ID is opened, automatically rewrite any backlinks in other notes that still use an outdated filename for that ID.",
            "type": "boolean",
            "default": true
        }
    ]

    function init() {
        script.registerCustomAction("zkInsertId", "Insert Zettelkasten ID", "ZK-ID", "", false, false, true);
        script.registerCustomAction("zkInsertLink", "Insert Zettelkasten link", "ZK-Link", "", false, false, true);
        script.registerCustomAction("zkRepairLinks", "Repair Zettelkasten links", "ZK-Fix", "", false, false, false);
    }

    function customActionInvoked(identifier) {
        if (identifier === "zkInsertId") {
            insertZkId();
        } else if (identifier === "zkInsertLink") {
            insertZkLink();
        } else if (identifier === "zkRepairLinks") {
            repairAllLinks();
        }
    }

    function noteOpenedHook(note) {
        if (autoRepairLinks !== false) {
            repairBacklinksFor(note);
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    function generateId() {
        var fmt = (idFormat || "").trim() || "%Y%M%D%h%m%s";
        var d = new Date();
        var p = function (n) {
            return n < 10 ? "0" + n : String(n);
        };
        return fmt.replace(/%Y/g, String(d.getFullYear())).replace(/%M/g, p(d.getMonth() + 1)).replace(/%D/g, p(d.getDate())).replace(/%h/g, p(d.getHours())).replace(/%m/g, p(d.getMinutes())).replace(/%s/g, p(d.getSeconds()));
    }

    function extractId(text) {
        try {
            var re = new RegExp(idRegex || "\\d{14}");
            // Strip [[target|id]] links before matching so a linked ID is never
            // mistaken for the note's own ID (which would corrupt idMap).
            var m = text.replace(/\[\[[^\]|]*\|[^\]]*\]\]/g, "").match(re);
            return m ? m[0] : null;
        } catch (e) {
            script.log("zettelkasten: invalid ID regex — " + e);
            return null;
        }
    }

    // Returns the link target string for [[target|id]] given a note object.
    // QOwnNotes resolves wiki-links by filename only, regardless of subfolder,
    // so we never include the relative directory path.
    function noteLinkTarget(note) {
        var name = note && note.name ? note.name : "";
        if (name)
            return name;
        return /\.txt$/i.test(note.fileName) ? note.fileName.slice(0, note.fileName.length - 4) : note.fileName;
    }

    function regEscape(s) {
        return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    }

    // ── Backlink repair ───────────────────────────────────────────────────────

    // When a note is opened, find all notes that link to its ZK ID with a
    // stale filename and rewrite those links to use the current filename.
    function repairBacklinksFor(note) {
        if (!note || !note.fileName)
            return;
        var zkId = extractId(note.fileName);
        if (!zkId)
            zkId = extractId(note.noteText);
        if (!zkId)
            return;
        var currentTarget = noteLinkTarget(note);

        // Fetch notes that contain the literal string "|zkId]]"
        var candidates = script.fetchNoteIdsByNoteTextPart("|" + zkId + "]]");
        var pattern = new RegExp("\\[\\[([^\\]|]*)\\|" + regEscape(zkId) + "\\]\\]", "g");
        for (var i = 0; i < candidates.length; i++) {
            var n = script.fetchNoteById(candidates[i]);
            if (!n || !n.noteText || !n.fullNoteFilePath)
                continue;
            var changed = false;
            var newText = n.noteText.replace(pattern, function (match, oldTarget) {
                if (oldTarget === currentTarget)
                    return match;
                changed = true;
                return "[[" + currentTarget + "|" + zkId + "]]";
            });
            if (changed) {
                script.writeToFile(n.fullNoteFilePath, newText);
                script.log("zettelkasten: repaired backlink in \"" + n.fileName + "\" → [[" + currentTarget + "|" + zkId + "]]");
            }
        }
    }

    // Full vault scan: build an id→currentTarget map, then rewrite every
    // [[staleTarget|id]] in every note.
    function repairAllLinks() {
        var allIds = script.fetchNoteIdsByNoteTextPart("");

        // Build zkId → correct link target
        var idMap = {};
        for (var i = 0; i < allIds.length; i++) {
            var note = script.fetchNoteById(allIds[i]);
            if (!note || !note.fileName)
                continue;
            var zkId = extractId(note.fileName);
            if (!zkId)
                zkId = extractId(note.noteText);
            if (!zkId)
                continue;
            idMap[zkId] = noteLinkTarget(note);
        }
        var pattern = /\[\[([^\]|]*)\|([^\]]*)\]\]/g;
        var repairedLinks = 0;
        var repairedNotes = 0;
        for (var j = 0; j < allIds.length; j++) {
            var n = script.fetchNoteById(allIds[j]);
            if (!n || !n.noteText || !n.fullNoteFilePath)
                continue;
            var changed = false;
            var newText = n.noteText.replace(pattern, function (match, linkTarget, linkId) {
                var correct = idMap[linkId];
                if (!correct || correct === linkTarget)
                    return match;
                changed = true;
                repairedLinks++;
                return "[[" + correct + "|" + linkId + "]]";
            });
            if (changed) {
                script.writeToFile(n.fullNoteFilePath, newText);
                repairedNotes++;
            }
        }
        script.informationMessageBox(repairedLinks > 0 ? "Repaired " + repairedLinks + " link(s) in " + repairedNotes + " note(s)." : "All Zettelkasten links are up to date.", "Zettelkasten");
    }

    // ── Actions ───────────────────────────────────────────────────────────────
    function insertZkId() {
        script.noteTextEditWrite(generateId());
    }

    function insertZkLink() {
        var noteIds = script.fetchNoteIdsByNoteTextPart("");
        var entries = [];
        for (var i = 0; i < noteIds.length; i++) {
            var note = script.fetchNoteById(noteIds[i]);
            if (!note || !note.fileName)
                continue;

            // Check filename first, then full content — first match only
            var zkId = extractId(note.fileName);
            if (!zkId)
                zkId = extractId(note.noteText);
            if (!zkId)
                continue;
            entries.push({
                "label": zkId + "  —  " + note.name,
                "linkTarget": noteLinkTarget(note),
                "zkId": zkId
            });
        }
        if (entries.length === 0) {
            script.informationMessageBox("No note with a Zettelkasten ID was found.\nPattern: " + (idRegex || "\\d{14}"), "Zettelkasten");
            return;
        }

        // Most recent first
        entries.sort(function (a, b) {
            return b.zkId > a.zkId ? 1 : b.zkId < a.zkId ? -1 : 0;
        });
        var component = Qt.createComponent(Qt.resolvedUrl("ZkLinkDialog.qml"));
        if (component.status !== Component.Ready) {
            script.informationMessageBox("Failed to load ZkLinkDialog:\n" + component.errorString(), "Zettelkasten");
            return;
        }
        var dialog = component.createObject(null, {
            "entries": entries
        });
        if (!dialog) {
            script.informationMessageBox("Failed to instantiate ZkLinkDialog.", "Zettelkasten");
            return;
        }
        dialog.linkSelected.connect(function (linkTarget, zkId) {
            script.noteTextEditWrite("[[" + linkTarget + "|" + zkId + "]]");
        });
        dialog.show();
        dialog.raise();
        dialog.requestActivate();
    }
}
