import QtQuick 2.0
import QtTest 1.3
import "../toc.js" as Toc

TestCase {
    name: "TableOfContents"

    function normalizedDepths(depths) {
        var toc = [];
        for (var i = 0; i < depths.length; i++) {
            toc.push({
                "depth": depths[i]
            });
        }

        Toc.normalizeDepths(toc);

        var result = [];
        for (var j = 0; j < toc.length; j++) {
            result.push(toc[j].depth);
        }
        return result;
    }

    function compareDepths(actual, expected) {
        compare(actual.length, expected.length);
        for (var i = 0; i < expected.length; i++) {
            compare(actual[i], expected[i]);
        }
    }

    function test_consecutiveLevels() {
        compareDepths(normalizedDepths([1, 2, 3, 3, 2]), [0, 1, 2, 2, 1]);
    }

    function test_skippedLevel() {
        compareDepths(normalizedDepths([1, 3, 3]), [0, 1, 1]);
    }

    function test_skippedAndReturningLevels() {
        compareDepths(normalizedDepths([1, 3, 4, 3, 2, 4]), [0, 1, 2, 1, 1, 2]);
    }

    function test_newShallowerRoot() {
        compareDepths(normalizedDepths([3, 4, 2, 3]), [0, 1, 0, 1]);
    }

    function test_emptyTableOfContents() {
        compareDepths(normalizedDepths([]), []);
    }
}
