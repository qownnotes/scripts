import QtQml 2.0

/**
 * url2markup — Convert bare URLs to Markdown links
 *
 * Two functions:
 *
 * 1. Selection → Markdown links  (custom action / context menu)
 *    Select text containing bare URLs, then invoke the action.  Every bare URL
 *    in the selection is replaced with a [Page Title](url) Markdown link.
 *    The page title is fetched live; smart trimming strips site-name suffixes
 *    and code-hosting metadata (issue/PR numbers, "by user", etc.).
 *    Suggested keyboard shortcut: assign Ctrl+Shift+K in
 *    QOwnNotes Settings › Shortcuts › "Convert URLs in selection to Markdown links".
 *
 * 2. Clipboard URL → Markdown link  (custom action)
 *    Copy a URL to the clipboard, then invoke the action to insert a resolved
 *    [Page Title](url) link at the cursor position.
 *    Suggested keyboard shortcut: assign Ctrl+Shift+W in
 *    QOwnNotes Settings › Shortcuts › "Paste clipboard URL as Markdown link".
 */
QtObject {

    // ------------------------------------------------------------------
    // HTML entity decoding
    // ------------------------------------------------------------------

    /**
     * Converts a Unicode code point to a JS string, correctly handling
     * supplementary characters (code points > U+FFFF) via surrogate pairs
     * for engines that do not yet support String.fromCodePoint.
     */
    function codePointToString(cp) {
        if (typeof String.fromCodePoint === "function") return String.fromCodePoint(cp);
        if (cp <= 0xFFFF) return String.fromCharCode(cp);
        // Construct surrogate pair for code points above the BMP.
        cp -= 0x10000;
        return String.fromCharCode((cp >> 10) + 0xD800, (cp & 0x3FF) + 0xDC00);
    }

    function decodeHtmlEntities(str) {
        return str
            .replace(/&amp;/g,  "&")
            .replace(/&lt;/g,   "<")
            .replace(/&gt;/g,   ">")
            .replace(/&quot;/g, '"')
            .replace(/&#39;/g,  "'")
            .replace(/&apos;/g, "'")
            .replace(/&nbsp;/g, " ")
            .replace(/&#(\d+);/g,        function(m, n) { return codePointToString(parseInt(n, 10)); })
            .replace(/&#x([0-9a-fA-F]+);/g, function(m, h) { return codePointToString(parseInt(h, 16)); });
    }

    // ------------------------------------------------------------------
    // Smart title trimming
    // ------------------------------------------------------------------

    function isCodeHostUrl(url) {
        return /^https?:\/\/(?:www\.)?(github\.com|gitlab\.com|bitbucket\.org|codeberg\.org)/i.test(url);
    }

    /**
     * Trims a raw <title> string to a concise, clean link label.
     *
     * Code-hosting URLs (GitHub, GitLab, Bitbucket, Codeberg):
     *   • Strips the "by user · Pull Request/Issue/Discussion/Merge Request #N · owner/repo"
     *     suffix that these platforms append to page titles.
     *
     * All other URLs:
     *   • Removes a trailing " | Site Name", " · Site", " — Site", or " – Site" suffix.
     *   • For a single " - " separator (plain hyphen), strips the suffix only when it
     *     appears exactly once (avoids mangling titles that legitimately contain hyphens).
     *   • Falls back to the full title when no recognisable separator is present.
     */
    function smartTrimTitle(url, title) {
        if (isCodeHostUrl(url)) {
            // "Fix bug by user · Pull Request #N · owner/repo" → "Fix bug"
            // "Fix bug · Issue #N · owner/repo"               → "Fix bug"
            title = title.replace(
                /(\s+by\s+\S+)?\s+[·•]\s+(?:Pull Request|Issue|Discussion|Merge Request)\s+#?\d+\s+[·•]\s+.*$/i,
                ""
            );
            // Strip any remaining " · Something · GitHub/GitLab/…" tail
            title = title.replace(
                /\s+[·•]\s+.*?\s+[·•]\s+(?:GitHub|GitLab|Bitbucket|Codeberg)\s*$/i,
                ""
            );
            // Strip simple " · GitHub" etc.
            title = title.replace(
                /\s+[·•]\s+(?:GitHub|GitLab|Bitbucket|Codeberg)\s*$/i,
                ""
            );
            return title.trim();
        }

        // General: strip the site-name suffix that follows the last strong separator.
        var strongSeps = [" | ", " · ", " — ", " – "];
        for (var i = 0; i < strongSeps.length; i++) {
            var idx = title.lastIndexOf(strongSeps[i]);
            if (idx > 0) {
                return title.substring(0, idx).trim();
            }
        }

        // Plain hyphen: only strip when there is exactly one occurrence.
        var hyphenIdx = title.lastIndexOf(" - ");
        if (hyphenIdx > 0 && title.indexOf(" - ") === hyphenIdx) {
            return title.substring(0, hyphenIdx).trim();
        }

        return title;
    }

    // ------------------------------------------------------------------
    // URL helpers
    // ------------------------------------------------------------------

    /**
     * Escapes characters that are significant inside a Markdown link label
     * ( [ and ] would break [label](url) syntax) and collapses newlines to
     * spaces so multi-line titles don't corrupt the note text.
     */
    function escapeMarkdownLinkText(text) {
        return text
            .replace(/\r?\n|\r/g, " ")
            .replace(/\[/g, "\\[")
            .replace(/\]/g, "\\]");
    }

    /**
     * Strips trailing sentence-punctuation characters that are almost certainly
     * not part of the URL.  For closing parentheses, only strips extras that
     * are unbalanced (so Wikipedia-style URLs with "(…)" in the path are kept
     * intact).
     */
    function cleanUrlTrailing(url) {
        url = url.replace(/[.,;:!?]+$/, "");

        var opens  = (url.match(/\(/g) || []).length;
        var closes = (url.match(/\)/g) || []).length;
        while (closes > opens && url.length > 0 && url[url.length - 1] === ")") {
            url = url.slice(0, -1);
            closes--;
        }

        return url;
    }

    /**
     * Downloads a URL and returns the cleaned page title, or the URL itself
     * when the title cannot be determined.
     */
    function fetchPageTitle(url) {
        var html = script.downloadUrlToString(url);
        if (!html) return url;

        var m = /<title[^>]*>([\s\S]*?)<\/title>/i.exec(html);
        if (!m || !m[1]) return url;

        var title = decodeHtmlEntities(m[1].trim());
        if (!title) return url;

        return escapeMarkdownLinkText(smartTrimTitle(url, title) || url);
    }

    // ------------------------------------------------------------------
    // Core conversion: bare URLs → Markdown links
    // ------------------------------------------------------------------

    /**
     * Replaces every bare URL in `text` with a [Page Title](url) Markdown link.
     * Skips URLs that are already part of a Markdown link ([…](url)) or wrapped
     * in angle brackets (<url>).
     */
    function convertUrlsInText(text) {
        // Allow ( and ) inside the URL so that Wikipedia-style paths survive;
        // cleanUrlTrailing() will remove unbalanced trailing ) afterwards.
        var urlRe = /https?:\/\/[^\s\]<>"]+/g;
        var result    = "";
        var lastIndex = 0;
        var match;

        while ((match = urlRe.exec(text)) !== null) {
            var raw   = match[0];
            var start = match.index;
            var end   = start + raw.length;

            // Already inside a Markdown link: ]( url )
            if (start >= 2 && text.substring(start - 2, start) === "](") {
                result    += text.substring(lastIndex, end);
                lastIndex  = end;
                continue;
            }

            // Already inside an angle-bracket link: <url>
            if (start >= 1 && text.charAt(start - 1) === "<") {
                result    += text.substring(lastIndex, end);
                lastIndex  = end;
                continue;
            }

            var cleanUrl     = cleanUrlTrailing(raw);
            var trailingPunct = raw.substring(cleanUrl.length);
            var linkText     = fetchPageTitle(cleanUrl);

            result    += text.substring(lastIndex, start);
            result    += "[" + linkText + "](" + cleanUrl + ")";
            result    += trailingPunct;
            lastIndex  = end;
        }

        result += text.substring(lastIndex);
        return result;
    }

    // ------------------------------------------------------------------
    // Initialisation: register custom actions
    // ------------------------------------------------------------------

    function init() {
        // Function 1 — selection to Markdown links
        // Suggested shortcut: Ctrl+Shift+K (assign in Settings › Shortcuts)
        script.registerCustomAction(
            "url2markup-selection",
            qsTr("Convert URLs in selection to Markdown links"),
            "",            // no toolbar button label
            "insert-link", // freedesktop icon
            true,          // show in note-edit context menu
            true,          // hide button in toolbar
            false          // not in note-list context menu
        );

        // Function 2 — clipboard URL to Markdown link
        // Suggested shortcut: Ctrl+Shift+W (assign in Settings › Shortcuts)
        script.registerCustomAction(
            "url2markup-clipboard",
            qsTr("Paste clipboard URL as Markdown link"),
            "",
            "insert-link",
            true,
            true,
            false
        );
    }

    // ------------------------------------------------------------------
    // Custom action handler
    // ------------------------------------------------------------------

    function customActionInvoked(identifier) {
        if (identifier === "url2markup-selection") {
            var sel = script.noteTextEditSelectedText();
            if (!sel || sel.trim() === "") {
                script.informationMessageBox(
                    qsTr("Please select text containing bare URLs first."),
                    qsTr("URL → Markdown Link")
                );
                return;
            }

            var converted = convertUrlsInText(sel);
            if (converted !== sel) {
                script.noteTextEditWrite(converted);
            }
            return;
        }

        if (identifier === "url2markup-clipboard") {
            var clipUrl = script.clipboard().trim();
            if (!/^https?:\/\/\S+$/i.test(clipUrl)) {
                script.informationMessageBox(
                    qsTr("Clipboard does not contain a single bare URL."),
                    qsTr("URL → Markdown Link")
                );
                return;
            }

            var linkText = fetchPageTitle(clipUrl);
            script.noteTextEditWrite("[" + linkText + "](" + clipUrl + ")");
        }
    }

}
