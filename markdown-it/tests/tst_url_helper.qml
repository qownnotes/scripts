import QtQuick 2.0
import QtTest 1.3
import "../url-helper.js" as UrlHelper

TestCase {
    name: "MarkdownItUrlHelper"

    function test_modernMediaLinkFromNestedNote() {
        compare(UrlHelper.localFileUrl("../../media/image.png", "/notes/projects/work", "/notes", false), "file:///notes/media/image.png");
    }

    function test_legacyMediaLink() {
        compare(UrlHelper.localFileUrl("file://media/image.png", "/notes/projects", "/notes", false), "file:///notes/media/image.png");
    }

    function test_remoteImageIsUnchanged() {
        var url = "https://www.servernoobs.com/wp-content/uploads/2012/01/Linux-3.jpg";
        compare(UrlHelper.localFileUrl(url, "/notes", "/notes", false), url);
    }

    function test_windowsPath() {
        compare(UrlHelper.localFileUrl("../media/image.png", "C:\\Notes\\nested", "C:\\Notes", true), "file:///C:/Notes/media/image.png");
    }

    function test_rewritePreservesAttributeQuotes() {
        var html = "<img src='media/image.png'><a href=\"#section\">link</a>";
        compare(UrlHelper.rewriteLocalUrls(html, "/notes", "/notes", false), "<img src='file:///notes/media/image.png'><a href=\"#section\">link</a>");
    }
}
