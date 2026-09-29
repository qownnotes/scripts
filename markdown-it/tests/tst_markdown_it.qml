import QtQuick 2.0
import QtTest 1.3
import "../markdown-it-deflist.js" as MarkdownItDeflist
import "../markdown-it-katex.js" as MarkdownItKatex
import "../markdown-it.js" as MarkdownIt

TestCase {
    name: "MarkdownItLibraries"

    function test_librariesAreGloballyAvailable() {
        compare(typeof markdownit, "function");
        compare(typeof markdownitDeflist, "function");
        compare(typeof markdownItKatex, "function");
    }

    function test_renderWithPlugins() {
        var md = new markdownit({});
        md.use(markdownitDeflist);
        markdownItKatex(md, {
            "output": "mathml"
        });
        var html = md.render("# Title\n\nTerm\n: Definition\n\n$x^2$");
        verify(html.indexOf("<h1>Title</h1>") !== -1);
        verify(html.indexOf("<dt>Term</dt>") !== -1);
        verify(html.indexOf("<math") !== -1);
    }
}
