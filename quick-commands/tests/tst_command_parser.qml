import QtQuick 2.0
import QtTest 1.3
import "../command-parser.js" as CommandParser

TestCase {
    name: "QuickCommandParser"

    function compareValues(actual, expected) {
        compare(actual.length, expected.length);
        for (var i = 0; i < expected.length; i++) {
            compare(actual[i], expected[i]);
        }
    }

    function test_plainValuesRemainSeparate() {
        var result = CommandParser.parseCommandLine("colour red green blue");

        compare(result.name, "colour");
        compareValues(result.values, ["red", "green", "blue"]);
    }

    function test_quotedMultiWordValue() {
        var result = CommandParser.parseCommandLine('myname "Firstname Lastname"');

        compare(result.name, "myname");
        compareValues(result.values, ["Firstname Lastname"]);
    }

    function test_mixedValues() {
        var result = CommandParser.parseCommandLine('greeting hello "Hello world" goodbye');

        compareValues(result.values, ["hello", "Hello world", "goodbye"]);
    }

    function test_whitespace() {
        var result = CommandParser.parseCommandLine('  greeting\t"Hello world"   goodbye  ');

        compare(result.name, "greeting");
        compareValues(result.values, ["Hello world", "goodbye"]);
    }

    function test_escapedCharacters() {
        var result = CommandParser.parseCommandLine('message "Say \\"hello\\" from C:\\\\Temp"');

        compareValues(result.values, ['Say "hello" from C:\\Temp']);
    }

    function test_escapedSpaceOutsideQuotes() {
        var result = CommandParser.parseCommandLine("myname Firstname\\ Lastname");

        compareValues(result.values, ["Firstname Lastname"]);
    }

    function test_invalidRows() {
        compare(CommandParser.parseCommandLine(""), null);
        compare(CommandParser.parseCommandLine("command"), null);
        compare(CommandParser.parseCommandLine('command ""'), null);
        compare(CommandParser.parseCommandLine('command "unclosed value'), null);
    }
}
