import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script suggests a new note title with the AI completer,
 * lets the user review or edit it, and then updates the note text.
 */
Script {
    property int linesToSend
    property variant settingsVariables: [
        {
            "identifier": "linesToSend",
            "name": "Number of note lines to send",
            "description": "Only the first N lines of the current note are sent to the AI completer when generating a title.",
            "type": "integer",
            "default": 20
        },
    ]

    function init() {
        script.registerCustomAction("generate-ai-note-title", "Generate AI Note Title", "AI Title", "network-server-database", true, true, false);
    }

    function customActionInvoked(identifier) {
        if (identifier !== "generate-ai-note-title") {
            return;
        }

        const currentNote = getCurrentNote();
        const noteText = readCurrentNoteText(currentNote);

        if (noteText === null) {
            script.informationMessageBox("The current note text could not be read. Please open a note and try again.", "AI Note Title");
            return;
        }

        const noteExcerpt = getNoteExcerpt(noteText);

        if (noteExcerpt === "") {
            script.informationMessageBox("There is no note text to generate a title from.", "AI Note Title");
            return;
        }

        let suggestedTitle = script.aiComplete(buildPrompt(noteExcerpt));
        suggestedTitle = normalizeTitle(suggestedTitle);

        if (suggestedTitle === "") {
            script.informationMessageBox("The AI completer did not return a usable title.", "AI Note Title");
            return;
        }

        const finalTitle = normalizeTitle(script.inputDialogGetText("AI Note Title", "Review or edit the suggested title before updating the note.", suggestedTitle));

        if (finalTitle === "") {
            return;
        }

        const updatedNoteText = replaceNoteTitle(noteText, finalTitle);

        if (updatedNoteText === noteText) {
            return;
        }

        script.triggerMenuAction("actionAllow_note_editing", 1);
        mainWindow.focusNoteTextEdit();
        script.noteTextEditSelectAll();
        script.noteTextEditWrite(updatedNoteText);
    }

    function getCurrentNote() {
        if (typeof script.currentNote === "function") {
            return script.currentNote();
        }

        if (script.currentNote !== undefined) {
            return script.currentNote;
        }

        return null;
    }

    function readCurrentNoteText(currentNote) {
        if (currentNote && currentNote.noteText !== undefined && currentNote.noteText !== null) {
            return String(currentNote.noteText);
        }

        const selectionStart = script.noteTextEditSelectionStart();
        const selectionEnd = script.noteTextEditSelectionEnd();

        script.noteTextEditSelectAll();
        const editorText = script.noteTextEditSelectedText();
        script.noteTextEditSetSelection(selectionStart, selectionEnd);

        if (editorText !== undefined && editorText !== null) {
            return String(editorText);
        }

        return null;
    }

    function getNoteExcerpt(noteText) {
        const maxLines = Math.max(1, linesToSend || 20);
        return noteText.split(/\r?\n/).slice(0, maxLines).join("\n").trim();
    }

    function buildPrompt(noteExcerpt) {
        return "Generate a concise title for this note based on the content below. Ignore any existing title or heading already present. Return only the title text, with no markdown, no quotes, and no explanation.\n\n" + noteExcerpt;
    }

    function normalizeTitle(value) {
        if (value === null || value === undefined) {
            return "";
        }

        let title = value.replace(/\r/g, "").trim();
        title = title.replace(/^#+\s*/, "");
        title = title.replace(/^["'`]+|["'`]+$/g, "");
        title = title.replace(/\n+/g, " ");

        return title.trim();
    }

    function replaceNoteTitle(noteText, title) {
        const frontmatterMatch = noteText.match(/^(---\r?\n[\s\S]*?\r?\n(?:---|\.\.\.)\r?\n?)([\s\S]*)$/);
        let prefix = "";
        let body = noteText;

        if (frontmatterMatch) {
            prefix = replaceFrontmatterTitle(frontmatterMatch[1], title);
            body = frontmatterMatch[2];
        }

        return prefix + replaceBodyTitle(body, title);
    }

    function replaceFrontmatterTitle(frontmatter, title) {
        const yamlTitleLine = "title: " + quoteYamlString(title);

        if (/^title:[ \t]*/m.test(frontmatter)) {
            return frontmatter.replace(/^title:[ \t]*.*$/m, function () {
                return yamlTitleLine;
            });
        }

        return frontmatter.replace(/(\r?\n)(---|\.\.\.)(\r?\n?)$/, function (_, lineBreak, closer, trailingLineBreak) {
            return lineBreak + yamlTitleLine + lineBreak + closer + trailingLineBreak;
        });
    }

    function quoteYamlString(value) {
        return '"' + value.replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';
    }

    function replaceBodyTitle(body, title) {
        const leadingWhitespaceMatch = body.match(/^(\s*)/);
        const leadingWhitespace = leadingWhitespaceMatch ? leadingWhitespaceMatch[1] : "";
        const remainingBody = body.slice(leadingWhitespace.length);

        const atxHeadingMatch = remainingBody.match(/^(#{1,6})[ \t]+[^\r\n]*(\r?\n|$)/);
        if (atxHeadingMatch) {
            return leadingWhitespace + remainingBody.replace(/^(#{1,6})[ \t]+[^\r\n]*(\r?\n|$)/, function (_, hashes, lineBreak) {
                return hashes + " " + title + lineBreak;
            });
        }

        const setextHeadingMatch = remainingBody.match(/^([^\r\n]+)(\r?\n)([=-]{3,})(\r?\n|$)/);
        if (setextHeadingMatch) {
            return leadingWhitespace + remainingBody.replace(/^([^\r\n]+)(\r?\n)([=-]{3,})(\r?\n|$)/, function (_, __, lineBreak, underline, trailingLineBreak) {
                return title + lineBreak + underline + trailingLineBreak;
            });
        }

        if (remainingBody === "") {
            return "# " + title + "\n";
        }

        return leadingWhitespace + "# " + title + "\n\n" + remainingBody;
    }
}
