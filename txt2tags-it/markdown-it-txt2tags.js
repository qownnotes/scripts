/*! markdown-it-txt2tags - txt2tags syntax support for markdown-it */
(function (f) {
  if (typeof exports === "object" && typeof module !== "undefined") {
    module.exports = f();
  } else if (typeof define === "function" && define.amd) {
    define([], f);
  } else {
    var g;
    if (typeof window !== "undefined") {
      g = window;
    } else if (typeof global !== "undefined") {
      g = global;
    } else if (typeof self !== "undefined") {
      g = self;
    } else if (typeof globalThis !== "undefined") {
      g = globalThis;
    } else {
      g = this;
    }
    g.markdownitTxt2tags = f();
  }
})(function () {
  "use strict";

  /**
   * txt2tags syntax support for markdown-it
   *
   * Block rules:
   *   = Heading 1 =  /  == Heading 2 ==  /  …  /  ===== Heading 5 =====
   *   % This is a comment (line ignored in output)
   *
   * Inline rules:
   *   //italic//     →  <em>italic</em>
   *   __underline__  →  <u>underline</u>
   *   --strikethrough--  →  <del>strikethrough</del>
   */
  function txt2tagsPlugin(md) {

    // ── Override text rule to also stop at / (needed for //italic//) ─────────
    // markdown-it's built-in text rule stops at isTerminatorChar characters.
    // '/' (0x2F) is not in that set, so '//italic//' gets consumed as plain
    // text before the italic inline rule can match it.
    function isTerminatorCharExtended(ch) {
      // 0x2F = '/' — added for txt2tags //italic//
      if (ch === 0x2F) return true;
      // Replicate markdown-it's isTerminatorChar exactly (v8.4.2)
      switch (ch) {
        case 0x0a: case 0x21: case 0x23: case 0x24: case 0x25: case 0x26:
        case 0x2a: case 0x2b: case 0x2d: case 0x3a: case 0x3c: case 0x3d:
        case 0x3e: case 0x40: case 0x5b: case 0x5c: case 0x5d: case 0x5e:
        case 0x5f: case 0x60: case 0x7b: case 0x7d: case 0x7e:
          return true;
        default:
          return false;
      }
    }
    md.inline.ruler.at("text", function (state, silent) {
      var pos = state.pos;
      while (pos < state.posMax && !isTerminatorCharExtended(state.src.charCodeAt(pos))) {
        pos++;
      }
      if (pos === state.pos) return false;
      if (!silent) state.pending += state.src.slice(state.pos, pos);
      state.pos = pos;
      return true;
    });

    // ── Block: headings ──────────────────────────────────────────────────────
    // = H1 =   == H2 ==   === H3 ===   ==== H4 ====   ===== H5 =====
    // Rules:
    //   - The number of = signs must match on both sides (1–5)
    //   - At least one space between the = signs and the title text
    //   - Trailing spaces after the closing = signs are allowed
    md.block.ruler.before(
      "heading",
      "txt2tags_heading",
      function (state, startLine, endLine, silent) {
        var pos = state.bMarks[startLine] + state.tShift[startLine];
        var max = state.eMarks[startLine];

        if (state.src.charCodeAt(pos) !== 0x3d /* = */) return false;

        var line = state.src.slice(pos, max);
        var match = /^(={1,5}) +(.+?) +\1\s*$/.exec(line);
        if (!match) return false;

        var level = match[1].length;
        var title = match[2];

        if (silent) return true;

        var token;
        token = state.push("heading_open", "h" + level, 1);
        token.markup = match[1];
        token.map = [startLine, startLine + 1];

        token = state.push("inline", "", 0);
        token.content = title;
        token.map = [startLine, startLine + 1];
        token.children = [];

        token = state.push("heading_close", "h" + level, -1);
        token.markup = match[1];

        state.line = startLine + 1;
        return true;
      }
    );

    // ── Block: % comments ────────────────────────────────────────────────────
    // A line whose very first character is % is silently consumed.
    md.block.ruler.before(
      "paragraph",
      "txt2tags_comment",
      function (state, startLine, endLine, silent) {
        // Use bMarks (not bMarks + tShift) to require % at column 0
        var pos = state.bMarks[startLine];
        if (state.src.charCodeAt(pos) !== 0x25 /* % */) return false;
        if (silent) return true;
        state.line = startLine + 1;
        return true;
      }
    );

    // ── Block: + numbered list ───────────────────────────────────────────────
    // Lines starting with '+ ' (plus space) form an ordered list.
    // Registered BEFORE 'list' so markdown-it's own list rule doesn't consume +.
    md.block.ruler.before(
      "list",
      "txt2tags_ordered_list",
      function (state, startLine, endLine, silent) {
        var pos = state.bMarks[startLine] + state.tShift[startLine];
        if (state.src.charCodeAt(pos) !== 0x2B /* + */ ||
            state.src.charCodeAt(pos + 1) !== 0x20 /* space */) return false;
        if (silent) return true;

        var items = [];
        var line = startLine;
        while (line < endLine) {
          pos = state.bMarks[line] + state.tShift[line];
          if (state.src.charCodeAt(pos) !== 0x2B ||
              state.src.charCodeAt(pos + 1) !== 0x20) break;
          items.push(state.src.slice(pos + 2, state.eMarks[line]));
          line++;
        }

        var token = state.push("ordered_list_open", "ol", 1);
        token.map = [startLine, line];
        token.markup = "+";

        for (var i = 0; i < items.length; i++) {
          token = state.push("list_item_open", "li", 1);
          token.map = [startLine + i, startLine + i + 1];
          token.markup = "+";

          token = state.push("inline", "", 0);
          token.content = items[i];
          token.map = [startLine + i, startLine + i + 1];
          token.children = [];

          state.push("list_item_close", "li", -1).markup = "+";
        }

        state.push("ordered_list_close", "ol", -1).markup = "+";
        state.line = line;
        return true;
      }
    );

    // ── Inline: //italic// ───────────────────────────────────────────────────
    // Avoid matching inside URLs (e.g. http://)
    md.inline.ruler.push(
      "txt2tags_italic",
      function (state, silent) {
        var pos = state.pos;
        var src = state.src;
        if (src.charCodeAt(pos) !== 0x2F || src.charCodeAt(pos + 1) !== 0x2F) return false;
        if (pos > 0 && src.charCodeAt(pos - 1) === 0x3A /* : */) return false;
        var start = pos + 2;
        var end = src.indexOf("//", start);
        if (end < 0 || end === start) return false;
        if (!silent) {
          state.push("em_open", "em", 1).markup = "//";
          state.push("text", "", 0).content = src.slice(start, end);
          state.push("em_close", "em", -1).markup = "//";
        }
        state.pos = end + 2;
        return true;
      }
    );

    // ── Inline: __underline__ ────────────────────────────────────────────────
    // Registered BEFORE 'emphasis' so that __ is consumed here instead of
    // being treated as markdown bold.
    md.inline.ruler.before(
      "emphasis",
      "txt2tags_underline",
      function (state, silent) {
        var pos = state.pos;
        var src = state.src;
        if (src.charCodeAt(pos) !== 0x5F || src.charCodeAt(pos + 1) !== 0x5F) return false;
        var start = pos + 2;
        var end = src.indexOf("__", start);
        if (end < 0 || end === start) return false;
        if (!silent) {
          state.push("txt2tags_u_open", "u", 1);
          state.push("text", "", 0).content = src.slice(start, end);
          state.push("txt2tags_u_close", "u", -1);
        }
        state.pos = end + 2;
        return true;
      }
    );

    // ── Inline: [label url] links ────────────────────────────────────────────
    // Registered BEFORE 'link' so markdown-it's own link rule doesn't consume [.
    // If the content matches [text](url) (standard markdown), we let the link
    // rule handle it by returning false when a '(' immediately follows ']'.
    md.inline.ruler.before(
      "link",
      "txt2tags_link",
      function (state, silent) {
        var pos = state.pos;
        var src = state.src;
        if (src.charCodeAt(pos) !== 0x5B /* [ */) return false;
        var closePos = src.indexOf("]", pos + 1);
        if (closePos < 0) return false;
        // Let standard markdown [text](url) pass through
        if (src.charCodeAt(closePos + 1) === 0x28 /* ( */) return false;
        var content = src.slice(pos + 1, closePos);
        // Last space separates label from URL
        var lastSpace = content.lastIndexOf(" ");
        if (lastSpace < 0) return false;
        var label = content.slice(0, lastSpace);
        var url = content.slice(lastSpace + 1);
        if (!label || !url) return false;
        // URL must start with a recognised scheme or /
        if (!/^[a-zA-Z][\w+\-.]*:\/\/|^\//.test(url)) return false;
        if (!silent) {
          var token = state.push("link_open", "a", 1);
          token.attrs = [["href", url]];
          token.markup = "txt2tags";
          state.push("text", "", 0).content = label;
          state.push("link_close", "a", -1).markup = "txt2tags";
        }
        state.pos = closePos + 1;
        return true;
      }
    );

    // ── Inline: bare URLs ────────────────────────────────────────────────────
    // Matches scheme://... URLs that appear without brackets.
    // Registered BEFORE the text rule so the text rule doesn't consume the
    // leading letters (it stops at '/' but would first consume e.g. "http:").
    md.inline.ruler.before(
      "text",
      "txt2tags_autolink",
      function (state, silent) {
        var pos = state.pos;
        var src = state.src;
        // Must start with a URL scheme (letters then "://")
        var match = /^[a-zA-Z][\w+\-.]*:\/\/[^\s\]]*/.exec(src.slice(pos));
        if (!match) return false;
        var url = match[0];
        // Strip trailing punctuation that is unlikely to be part of the URL
        url = url.replace(/[.,;:!?)]+$/, "");
        if (!url) return false;
        if (!silent) {
          var token = state.push("link_open", "a", 1);
          token.attrs = [["href", url]];
          token.markup = "autolink";
          state.push("text", "", 0).content = url;
          state.push("link_close", "a", -1).markup = "autolink";
        }
        state.pos = pos + url.length;
        return true;
      }
    );

    // ── Inline: [[wikilink]] and [[wikilink|description]] ────────────────────
    // Registered BEFORE 'txt2tags_link' (and therefore before 'link') so that
    // the double-bracket syntax is consumed before any single-bracket rule.
    md.inline.ruler.before(
      "txt2tags_link",
      "txt2tags_wikilink",
      function (state, silent) {
        var pos = state.pos;
        var src = state.src;
        // Must start with [[
        if (src.charCodeAt(pos) !== 0x5B || src.charCodeAt(pos + 1) !== 0x5B) return false;
        var closePos = src.indexOf("]]", pos + 2);
        if (closePos < 0) return false;
        var content = src.slice(pos + 2, closePos);
        if (!content) return false;
        // Split on first '|' to get optional description
        var pipePos = content.indexOf("|");
        var target, label;
        if (pipePos >= 0) {
          target = content.slice(0, pipePos);
          label  = content.slice(pipePos + 1);
        } else {
          target = content;
          label  = content;
        }
        if (!target) return false;
        // Append .md so the QOwnNotes hook resolves to a note file path
        var href = /\.md$/i.test(target) ? target : (target + ".md");
        if (!silent) {
          var token = state.push("link_open", "a", 1);
          token.attrs = [["href", href]];
          token.markup = "wikilink";
          state.push("text", "", 0).content = label;
          state.push("link_close", "a", -1).markup = "wikilink";
        }
        state.pos = closePos + 2;
        return true;
      }
    );

    // ── Inline: --strikethrough-- ─────────────────────────────────────────────
    md.inline.ruler.push(
      "txt2tags_strike",
      function (state, silent) {
        var pos = state.pos;
        var src = state.src;
        if (src.charCodeAt(pos) !== 0x2D || src.charCodeAt(pos + 1) !== 0x2D) return false;
        var start = pos + 2;
        var end = src.indexOf("--", start);
        if (end < 0 || end === start) return false;
        if (!silent) {
          state.push("txt2tags_s_open", "s", 1);
          state.push("text", "", 0).content = src.slice(start, end);
          state.push("txt2tags_s_close", "s", -1);
        }
        state.pos = end + 2;
        return true;
      }
    );
  }

  return txt2tagsPlugin;
});
