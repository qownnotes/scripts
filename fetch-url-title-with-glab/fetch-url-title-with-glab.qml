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

        if (target.kind === "work_items") {
            var query = "query($path: ID!, $iid: String!) { namespace(fullPath: $path) { workItem(iid: $iid) { title } } }";
            args.push("graphql", "-f", "query=" + query, "-f", "path=" + target.path, "-f", "iid=" + target.id);
        } else {
            args.push(projectEndpoint(target));
        }

        try {
            var result = api.startSynchronousProcess(glabPath, args);
            var data = JSON.parse(String(result));
            var title = titleFromResponse(target, data);

            if (typeof title === "string" && title.trim() !== "") {
                return title;
            }
        } catch (error) {
            // Don't log glab output, which may contain private project data.
        }

        api.log("Could not fetch GitLab URL title with glab.");
        return "";
    }

    function projectEndpoint(target) {
        var project = "projects/" + encodeURIComponent(target.path);

        switch (target.kind) {
        case "project":
            return project;
        case "commit":
            return project + "/repository/commits/" + target.id;
        case "milestones":
            // The web URL uses a project-local IID, not the API's global milestone ID.
            return project + "/milestones?iids%5B%5D=" + target.id;
        default:
            return project + "/" + target.kind + "/" + encodeURIComponent(target.id);
        }
    }

    function titleFromResponse(target, data) {
        if (!data) {
            return "";
        }

        switch (target.kind) {
        case "project":
            return data.name;
        case "work_items":
            var scope = data.data && data.data.namespace;
            return scope && scope.workItem && scope.workItem.title;
        case "releases":
            return typeof data.name === "string" && data.name.trim() !== "" ? data.name : data.tag_name;
        case "commit":
            return typeof data.message === "string" ? data.message.split(/\r?\n/, 1)[0] : data.title;
        case "milestones":
            return Array.isArray(data) && data[0] ? data[0].title : "";
        default:
            return data.title;
        }
    }

    function targetFromUrl(url) {
        var match = /^(https?:\/\/([a-z0-9][a-z0-9.-]*)(?::\d+)?)\/([^?#]*)(?:[?#].*)?$/i.exec(url.trim());

        if (match === null) {
            return null;
        }

        var path = match[3].replace(/\/$/, "");
        var kind = "project";
        var id = "";
        var subpage = /\/-\/(work_items|issues|merge_requests|releases|commit|milestones)\/([^/]+)$/.exec(path);

        if (subpage !== null) {
            kind = subpage[1];
            id = subpage[2];
            path = path.substring(0, subpage.index);

            if (kind === "releases") {
                try {
                    id = decodeURIComponent(id);
                } catch (error) {
                    return null;
                }

                if (id === "new" || id === "." || id === ".." || /[\x00-\x20\x7f\\]/.test(id)) {
                    return null;
                }
            } else if (kind === "commit" ? !/^[a-f0-9]{7,64}$/i.test(id) : !/^[1-9]\d*$/.test(id)) {
                return null;
            }
        }

        // Group work item URLs start with /groups/; the API expects just the namespace.
        var group = kind === "work_items" && path.indexOf("groups/") === 0;
        if (group) {
            path = path.substring("groups/".length);
        }

        if ((!group && path.indexOf("/") === -1) || !/^[a-z0-9_][a-z0-9_.-]*(?:\/[a-z0-9_][a-z0-9_.-]*)*$/i.test(path)) {
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
                    "kind": kind,
                    "id": id
                };
            }
        }

        return null;
    }
}
