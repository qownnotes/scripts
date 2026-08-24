function normalizePath(path) {
  return path.replace(/\\/g, "/");
}

function fileBasePath(path, isWindows) {
  path = normalizePath(path);
  return isWindows && !path.startsWith("/") ? "/" + path : path;
}

function resolvePath(base, relative) {
  var baseParts = base.replace(/\/+$/, "").split("/");
  var relParts = relative.replace(/^\.\/+/, "").split("/");

  for (var i = 0; i < relParts.length; i++) {
    var part = relParts[i];
    if (part === "..") baseParts.pop();
    else if (part !== "." && part !== "") baseParts.push(part);
  }

  return baseParts.join("/");
}

function localFileUrl(rawPath, noteDirectory, noteFolder, isWindows) {
  var legacyPath = rawPath.match(/^file:\/\/(media|attachments)\/(.*)$/i);
  if (legacyPath)
    return (
      "file://" +
      resolvePath(
        fileBasePath(noteFolder, isWindows),
        legacyPath[1] + "/" + legacyPath[2],
      )
    );

  if (
    /^[a-zA-Z][\w+.-]*:/.test(rawPath) ||
    rawPath.startsWith("//") ||
    rawPath.startsWith("#")
  )
    return rawPath;

  var path = normalizePath(rawPath);
  if (/^[a-zA-Z]:\//.test(path)) path = "/" + path;
  else if (!path.startsWith("/"))
    path = resolvePath(fileBasePath(noteDirectory, isWindows), path);

  return "file://" + path;
}

function rewriteLocalUrls(html, noteDirectory, noteFolder, isWindows) {
  return html.replace(
    /(\b(?:src|href|data-[\w-]+)\s*=\s*)(["'])([^"']+)\2/gi,
    function (_, attribute, quote, rawPath) {
      return (
        attribute +
        quote +
        localFileUrl(rawPath, noteDirectory, noteFolder, isWindows) +
        quote
      );
    },
  );
}
