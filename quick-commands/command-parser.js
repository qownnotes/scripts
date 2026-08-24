function parseCommandLine(line) {
  var tokens = [];
  var token = "";
  var tokenStarted = false;
  var inQuotes = false;
  var escaping = false;

  for (var i = 0; i < line.length; i++) {
    var character = line.charAt(i);

    if (escaping) {
      if (character === '"' || character === "\\" || /\s/.test(character)) {
        token += character;
      } else {
        token += "\\" + character;
      }
      tokenStarted = true;
      escaping = false;
    } else if (character === "\\") {
      escaping = true;
      tokenStarted = true;
    } else if (character === '"') {
      inQuotes = !inQuotes;
      tokenStarted = true;
    } else if (/\s/.test(character) && !inQuotes) {
      if (tokenStarted) {
        tokens.push(token);
        token = "";
        tokenStarted = false;
      }
    } else {
      token += character;
      tokenStarted = true;
    }
  }

  if (escaping) {
    token += "\\";
  }

  if (inQuotes) {
    return null;
  }

  if (tokenStarted) {
    tokens.push(token);
  }

  if (tokens.length < 2 || tokens[0] === "") {
    return null;
  }

  var values = [];
  for (var j = 1; j < tokens.length; j++) {
    if (tokens[j] !== "") {
      values.push(tokens[j]);
    }
  }

  if (values.length === 0) {
    return null;
  }

  return {
    name: tokens[0],
    values: values,
  };
}
