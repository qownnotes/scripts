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
        var project = projectFromUrl(url);

        if (project === null || glabPath.trim() === "") {
            return "";
        }

        var api = scriptApi || script;

        try {
            var result = api.startSynchronousProcess(glabPath, ["api", "--hostname", project.host, "projects/" + encodeURIComponent(project.path)]);
            var data = JSON.parse(String(result));

            if (data && typeof data.name === "string" && data.name.trim() !== "") {
                return data.name;
            }
        } catch (error) {
            // Don't log glab output, which may contain private project data.
        }

        api.log("Could not fetch GitLab project title with glab.");
        return "";
    }

    function projectFromUrl(url) {
        var match = /^(https?:\/\/([a-z0-9][a-z0-9.-]*)(?::\d+)?)\/([^?#]*)(?:[?#].*)?$/i.exec(url.trim());

        if (match === null) {
            return null;
        }

        // A project is namespaced and may be nested in subgroups. Don't treat
        // GitLab's /-/ subpages (issues, merge requests, etc.) as project URLs.
        var path = match[3].replace(/\/$/, "");

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
                    "path": path
                };
            }
        }

        return null;
    }
}
