import QtQuick 2.0
import QtTest 1.3

TestCase {
    name: "FetchUrlTitleWithGlab"

    property var titleScript
    property var calls
    property string processOutput

    function init() {
        calls = [];
        processOutput = '{"name":"Example Project","path":"example-project"}';
        var component = Qt.createComponent("../fetch-url-title-with-glab.qml");
        compare(component.status, Component.Ready, component.errorString());
        titleScript = createTemporaryObject(component, this, {
            "glabPath": "/custom/bin/glab",
            "gitlabBaseUrls": "https://gitlab.com\r\n\r\n HTTPS://gitlab.example.org/ \r\nhttps://gitlab.example.com:8443",
            "scriptApi": {
                "startSynchronousProcess": function (executable, argumentsList) {
                    calls.push([executable, argumentsList]);
                    return processOutput;
                },
                "log": function (message) {}
            }
        });
        verify(titleScript !== null);
    }

    function test_configuredProject() {
        compare(titleScript.fetchUrlTitleHook("https://gitlab.example.org/team/subgroup/example-project/?tab=overview#readme"), "Example Project");
        compare(calls, [["/custom/bin/glab", ["api", "--hostname", "gitlab.example.org", "projects/team%2Fsubgroup%2Fexample-project"]]]);
    }

    function test_customPort() {
        compare(titleScript.fetchUrlTitleHook("https://gitlab.example.com:8443/team/project"), "Example Project");
        compare(calls[0][1], ["api", "--hostname", "gitlab.example.com", "projects/team%2Fproject"]);
    }

    function test_ignoredUrls_data() {
        return [
            {
                "tag": "unconfigured host",
                "url": "https://example.com/team/project"
            },
            {
                "tag": "lookalike host",
                "url": "https://gitlab.example.org.example.com/team/project"
            },
            {
                "tag": "different scheme",
                "url": "http://gitlab.example.org/team/project"
            },
            {
                "tag": "different port",
                "url": "https://gitlab.example.org:8443/team/project"
            },
            {
                "tag": "user info",
                "url": "https://gitlab.example.org@example.com/team/project"
            },
            {
                "tag": "no namespace",
                "url": "https://gitlab.example.org/project"
            },
            {
                "tag": "issue",
                "url": "https://gitlab.example.org/team/project/-/issues/1"
            }
        ];
    }

    function test_ignoredUrls(data) {
        compare(titleScript.fetchUrlTitleHook(data.url), "");
        compare(calls.length, 0);
    }

    function test_failedLookup_data() {
        return [
            {
                "tag": "empty output",
                "output": ""
            },
            {
                "tag": "invalid JSON",
                "output": "glab error"
            },
            {
                "tag": "API error",
                "output": '{"message":"404 Project Not Found"}'
            },
            {
                "tag": "blank name",
                "output": '{"name":" "}'
            }
        ];
    }

    function test_failedLookup(data) {
        processOutput = data.output;
        compare(titleScript.fetchUrlTitleHook("https://gitlab.com/team/project"), "");
        compare(calls.length, 1);
    }
}
