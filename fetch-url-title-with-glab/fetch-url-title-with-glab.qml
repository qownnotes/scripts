import QtQml 2.0

QtObject {
    property string glabPath
    property string gitlabBaseUrls
    property var scriptApi

    property variant settingsVariables: [
        {
            "identifier": "glabPath",
            "name": "glab path",
            "description": "Please select the path to your glab executable:",
            "type": "file",
            "default": "glab"
        },
        {
            "identifier": "gitlabBaseUrls",
            "name": "GitLab base URLs",
            "description": "Enter GitLab server URLs (scheme and hostname, with an optional port), one per line. For private projects, run glab auth login --hostname HOST. Set the API protocol and port in glab for non-default setups.",
            "type": "text",
            "default": "https://gitlab.com"
        },
    ]

    // Returning an empty string lets QOwnNotes try its normal title lookup.
    function fetchUrlTitleHook(url) {
        var target = targetFromUrl(url);

        if (target === null || glabPath.trim() === "") {
            return "";
        }

        var api = scriptApi || script;
        var args = ["api", "--hostname", target.host];

        if (target.workItemIid) {
            var query = "query($path: ID!, $iid: String!) { namespace(fullPath: $path) { workItem(iid: $iid) { title } } }";
            args.push("graphql", "-f", "query=" + query, "-f", "path=" + target.path, "-f", "iid=" + target.workItemIid);
        } else {
            args.push("projects/" + encodeURIComponent(target.path));
        }

        try {
            var result = api.startSynchronousProcess(glabPath, args);
            var data = JSON.parse(String(result));
            var title;

            if (target.workItemIid) {
                var scope = data && data.data && data.data.namespace;
                title = scope && scope.workItem && scope.workItem.title;
            } else {
                title = data && data.name;
            }

            if (typeof title === "string" && title.trim() !== "") {
                return title;
            }
        } catch (error) {
            // Don't log glab output, which may contain private project data.
        }

        api.log("Could not fetch GitLab URL title with glab.");
        return "";
    }

    function targetFromUrl(url) {
        var match = /^(https?:\/\/([a-z0-9][a-z0-9.-]*)(?::\d+)?)\/([^?#]*)(?:[?#].*)?$/i.exec(url.trim());

        if (match === null) {
            return null;
        }

        // Handle work item URLs explicitly; other /-/ subpages are not project URLs.
        var path = match[3].replace(/\/$/, "");
        var workItem = /\/-\/work_items\/([1-9]\d*)$/.exec(path);

        if (workItem !== null) {
            path = path.substring(0, workItem.index);
        }

        if (!/^[a-z0-9_][a-z0-9_.-]*(?:\/[a-z0-9_][a-z0-9_.-]*)+$/i.test(path)) {
            return null;
        }

        var baseUrl = match[1].toLowerCase();
        var configuredUrls = gitlabBaseUrls.split(/\r?\n/);

        for (var i = 0; i < configuredUrls.length; i++) {
            if (configuredUrls[i].trim().replace(/\/+$/, "").toLowerCase() === baseUrl) {
                return {
                    // glab's --hostname only accepts the hostname. It uses
                    // its own configuration for the API protocol and port.
                    "host": match[2].toLowerCase(),
                    "path": path,
                    "workItemIid": workItem === null ? "" : workItem[1]
                };
            }
        }

        return null;
    }
}
