function normalizeDepths(toc) {
  // Active source heading levels map to consecutive Markdown list depths.
  var hierarchy = [];

  for (var i = 0; i < toc.length; i++) {
    var sourceDepth = toc[i].depth;

    while (
      hierarchy.length > 0 &&
      hierarchy[hierarchy.length - 1] >= sourceDepth
    ) {
      hierarchy.pop();
    }

    hierarchy.push(sourceDepth);
    toc[i].depth = hierarchy.length - 1;
  }

  return toc;
}
