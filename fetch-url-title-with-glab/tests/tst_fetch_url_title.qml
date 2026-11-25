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

    function test_workItem_data() {
        return [
            {
                "tag": "project work item",
                "path": "team/subgroup/example-project/-/work_items/2/?tab=activity#note_5",
                "namespace": "team/subgroup/example-project"
            },
            {
                "tag": "group work item",
                "path": "groups/team/-/work_items/2",
                "namespace": "team"
            },
            {
                "tag": "subgroup work item",
                "path": "groups/team/subgroup/-/work_items/2",
                "namespace": "team/subgroup"
            }
        ];
    }

    function test_workItem(data) {
        processOutput = '{"data":{"namespace":{"workItem":{"title":"Example Work Item"}}}}';
        compare(titleScript.fetchUrlTitleHook("https://gitlab.example.org/" + data.path), "Example Work Item");
        compare(calls.length, 1);
        compare(calls[0][0], "/custom/bin/glab");
        compare(calls[0][1].slice(0, 5), ["api", "--hostname", "gitlab.example.org", "graphql", "-f"]);
        verify(calls[0][1][5].indexOf("workItem(iid: $iid) { title }") !== -1);
        compare(calls[0][1].slice(6), ["-f", "path=" + data.namespace, "-f", "iid=2"]);
    }

    function test_workItemNotFound() {
        processOutput = '{"data":{"namespace":{"workItem":null}}}';
        compare(titleScript.fetchUrlTitleHook("https://gitlab.example.org/team/project/-/work_items/2"), "");
        compare(calls.length, 1);
    }

    function test_projectSubpage_data() {
        return [
            {
                "tag": "issue",
                "path": "issues/42?tab=activity#note_5",
                "endpoint": "issues/42",
                "output": {
                    "title": "Example Issue"
                },
                "title": "Example Issue"
            },
            {
                "tag": "merge request",
                "path": "merge_requests/17",
                "endpoint": "merge_requests/17",
                "output": {
                    "title": "Example Merge Request"
                },
                "title": "Example Merge Request"
            },
            {
                "tag": "named release",
                "path": "releases/v1.2.3",
                "endpoint": "releases/v1.2.3",
                "output": {
                    "name": "Example Release",
                    "tag_name": "v1.2.3"
                },
                "title": "Example Release"
            },
            {
                "tag": "release tag fallback",
                "path": "releases/release%2Fv1.2.3",
                "endpoint": "releases/release%2Fv1.2.3",
                "output": {
                    "name": "",
                    "tag_name": "release/v1.2.3"
                },
                "title": "release/v1.2.3"
            },
            {
                "tag": "commit",
                "path": "commit/abcdef1234",
                "endpoint": "repository/commits/abcdef1234",
                "output": {
                    "message": "Example Commit\r\n\r\nCommit description."
                },
                "title": "Example Commit"
            },
            {
                "tag": "milestone by IID",
                "path": "milestones/5",
                "endpoint": "milestones?iids%5B%5D=5",
                "output": [
                    {
                        "id": 100,
                        "iid": 5,
                        "title": "Example Milestone"
                    }
                ],
                "title": "Example Milestone"
            },
            {
                "tag": "missing milestone",
                "path": "milestones/5",
                "endpoint": "milestones?iids%5B%5D=5",
                "output": [],
                "title": ""
            }
        ];
    }

    function test_projectSubpage(data) {
        processOutput = JSON.stringify(data.output);
        compare(titleScript.fetchUrlTitleHook("https://gitlab.example.org/team/subgroup/example-project/-/" + data.path), data.title);
        compare(calls, [["/custom/bin/glab", ["api", "--hostname", "gitlab.example.org", "projects/team%2Fsubgroup%2Fexample-project/" + data.endpoint]]]);
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
                "tag": "unsupported subpage",
                "url": "https://gitlab.example.org/team/project/-/pipelines/1"
            },
            {
                "tag": "issue edit page",
                "url": "https://gitlab.example.org/team/project/-/issues/1/edit"
            },
            {
                "tag": "new release form",
                "url": "https://gitlab.example.org/team/project/-/releases/new"
            },
            {
                "tag": "malformed release tag encoding",
                "url": "https://gitlab.example.org/team/project/-/releases/v1%2"
            },
            {
                "tag": "work item on unconfigured host",
                "url": "https://example.com/team/project/-/work_items/2"
            },
            {
                "tag": "work item with invalid ID",
                "url": "https://gitlab.example.org/team/project/-/work_items/invalid"
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
