import QtQml 2.2
import QOwnNotesTypes 1.0

// This script is an import-tool from Obsidian and from VS Codium/Github/Typora/Pandoc into QOwnNotes. It adapts markdown links to fit QOwnNotes specific style (which is mostly pure urlencoded markdownlinks). 
// It encodes markdown links in order to profit from the whole QN functionality e.g. renaming Notenames  or moving notes to different folders and updating links to those notes. 
// Without the adaption of the links by this script, it might happen that uncommon links such as angle bracket links [file](<link to file.md>) will not be updated. 


Script {   
		function init() {
        // script.registerCustomAction("URIdecodePage", "URI decode all text in current page", ) // Uncomment for debugging 
        // script.registerCustomAction("URIencodeText", "URI encode selected text to QOwnNotes specific format (show '[]' instead of '%5B' and '%5D')", ) // Uncomment for debugging 
        script.registerCustomAction("ObsidianImport", "ObsidianImport: URI encode all files to QOwnNotes specific format (show '[]' instead of '%5B' and '%5D')", "ObsidianImport") 
        script.registerCustomAction("GFMImport", "GFMImport: Convert heading fragments in all files from Github/Markor/Pandoc - format [note](note.md#heading-with-dashes) to QOwnNotes format", "GFMImport")
		script.registerCustomAction("GFMExportAll", "GFMExportAll: Convert heading fragments in all files to Github/Markor/Pandoc - format [note](note.md#heading-with-dashes)", "GFMExportAll")  
		script.registerCustomAction("GFMExportPage", "GFMExportPage: Convert heading fragments in current page to Github/Markor/Pandoc - format [note](note.md#heading-with-dashes)", "GFMExportPage") 
		}

        function customActionInvoked(action) {
		var text; 
        var markdown;
		
		// <<<<------- Uncomment for debugging to check for specific link parts in note
        /* var currentSelectedText = script.noteTextEditSelectedText();
        if (action == "URIdecodePage") {
            text = script.noteTextEditSelectAll();
            text = script.noteTextEditSelectedText(); 
            var decodedlink = safeDecodeURI(text);
            decodedlink = decodedlink.replace(/%2C/gm, ",");
            script.noteTextEditWrite(decodedlink);
        }

        if (action == "URIencodeText") 
        {
            var encodedlink = encodeURI(decodeURI(currentSelectedText));
            encodedlink = encodedlink.replace(/\%5B/gm, "[");  
            encodedlink = encodedlink.replace(/\%5D/gm, "]");
            encodedlink = encodedlink.replace(/,/gm, "%2C");   // need to replace comma "," as with encodeURI comma remains untouched
            script.noteTextEditWrite(encodedlink);
        }   */
		// Uncomment for debugging ------->>>>>>   
		
		// Define a function to decode a link first. But a lot of times there are malformed links. So use catch to account for this. 
		function safeDecodeURI(uri) {
			try {
				return decodeURIComponent(uri);
			} catch (e) {
				return uri; // Return original if decoding fails
			}
		}
		
		// unused. Could not get this part working. Maybe in Version 2. Problem. I would have to use 2 variables as output, this makes code unecessary complicated. 
		/* function replaceCodeBlocks(markdown) {
			var codeBlocks = [];
			return markdown.replace(/(```[\s\S]*?```|`[^`]*`)/g, function (match) {
				codeBlocks.push(match);
				return "<<<CODE_BLOCK_" + (codeBlocks.length - 1) + ">>>";
			});
		}
			function restoreCodeBlocks(markdown, codeBlocks) {
			return markdown.replace(/<<<CODE_BLOCK_(\d+)>>>/g, function (match, index) {
				return codeBlocks[parseInt(index, 10)];
			});
		} */

		
		// function to take text, find all links, make them QN conform, then convert heading fragments [note](link.md#Everything%20After) to [note](link.md#everything-after)and adapt them to pandoc/github/markor style
		function produceDashedLinks(markdown) {
                // Identify and temporarily replace code blocks
                var codeBlocks = [];
				markdown = markdown.replace(/(```[\s\S]*?```|`[^`]*`)/g, function (match) {
				codeBlocks.push(match);
				return "<<<CODE_BLOCK_" + (codeBlocks.length - 1) + ">>>";
			});
				// Improved regex to correctly handle links with nested parentheses
                markdown = markdown.replace(/(^|[^`])\[([^\]]+)\]\((<)?((?:[^()]+|\([^()]*\))*)(>)?\)/g, function (match, prefix, text, openBracket, url, closeBracket) {
                    // Ignore external internet links
                    if (/^(https?:\/\/|www\.)/.test(url)) {
                        return match;
                    }

                    var titleMatch = url.match(/(".*")$/);
                    var title = titleMatch ? titleMatch[0] : '';
                    url = titleMatch ? url.substring(0, url.length - title.length) : url;   // Shorthand Ternary Operator (condition ? expr1 : expr2)   if (condition) expr1 else expr2
                    
                    // neu url replace instead of fragment replace
                    url = url.replace(/^<\s*|\s*>$/g, '').trim();
                    var urlParts = url.split('#');
                    var link = urlParts[0];
                    var fragment = urlParts.length > 1 ? urlParts[1] : '';  

                    // Remove angle brackets `< >` and trim spaces
                    // link = link.replace(/^<\s*|\s*>$/g, '').trim();

                    // Remove leading './' from relative paths
                    if (link.indexOf("./") === 0) {
                        link = link.substring(2);
                    }

                    // Encode the link and fragment properly
                    link = encodeURIComponent(safeDecodeURI(link)).replace(/%2E/g, ".").replace(/%2F/g, "/");
                    /*            
                    Pandoc Instructions: https://pandoc.org/demo/example33/7.2-headings-and-sections.html according to their website.
                    Remove all formatting, links, etc.
                    Remove all footnotes.
                    Remove all non-alphanumeric characters, except underscores, hyphens, and periods.
                    Replace all spaces and newlines with hyphens.
                    Convert all alphabetic characters to lowercase.
                    Remove everything up to the first letter (identifiers may not begin with a number or punctuation mark).
                    If nothing is left after this, use the identifier section.
                    */
                    //fragment = fragment.length > 0 ? safeDecodeURI(fragment).toLowerCase().replace(/\[\^([^\]]+)\]/,"").replace(/\[\^[0-9a-z]+\]/,"").trim().replace(/\s+/g,"-").replace(/^[^\p{L}]*/u, "") : '';
                    //fragment = fragment.length > 0 ? safeDecodeURI(fragment).toLowerCase().replace(/\s+/g, "-").replace(/[^\w\s_-]/g, "").replace(/[-_]+/g, "-").replace(/[\p{Emoji}\u200B-\u200D\uFE0F\u2B50\u20E3\u2122\u00AE]/gu, "") : '';
                    //fragment = fragment.length > 0 ? safeDecodeURI(fragment).toLowerCase().replace(/\s+/g, "-").replace(/[^\p{L}\d\s_-]/gu, "").replace(/[-_]+/g, "-").replace(/[\p{Emoji}\u200B-\u200D\uFE0F\u2B50\u20E3\u2122\u00AE]/gu, "") : '';
                    //fragment = fragment.length > 0 ? safeDecodeURI(fragment).toLowerCase().replace(/[^\w\d\s_-]/g, "").replace(/[-_]+/g, "-").replace(/^-+|-+$/g, "").replace(/[\p{Emoji}\u200B-\u200D\uFE0F\u2B50\u20E3\u2122\u00AE]/gu, "") : '';
                    //fragment = fragment.length > 0 ? safeDecodeURI(fragment).toLowerCase().replace(/[^\p{L}\p{N}\s\-]/gu, '').replace(/\s+/g, '-').replace(/^-+|-+$/g, '') : '';
                    //fragment = fragment.length > 0 ? safeDecodeURI(fragment).toLowerCase().replace(/[^\p{L}\p{N}\-]/gu, '-').replace(/^-+|-+$/g, '') : '';
                    //fragment = fragment.length > 0 ? safeDecodeURI(fragment).toLowerCase().replace(/[^a-z0-9\-]/g, '-').replace(/^-+|-+$/g, '') : '';
					//fragment = fragment.length > 0 ? safeDecodeURI(fragment).toLowerCase().replace(/[^\p{L}\p{N}\s-]/gu, '-') : '';
					//fragment = fragment.length > 0 ? safeDecodeURI(fragment).toLowerCase().replace(/[!-\/:-@[-`{-~]/g, '-').replace(/[\s-]+/g, '-').replace(/^-+|-+$/g, '') : '';
					//fragment = fragment.length > 0 ? safeDecodeURI(fragment).toLowerCase().replace(/[\uD800-\uDBFF][\uDC00-\uDFFF]|[\u2600-\u27BF]|[#*0-9]\uFE0F?\u20E3|[!"#$%&'()*+,.\/:;<=>?@\[\\\]^_`{|}~]/g, '').replace(/\s/g, '-').replace(/-+/g, '-') : '';
					fragment = fragment.length > 0 ? safeDecodeURI(fragment).trim().toLowerCase().replace(/[\uD800-\uDBFF][\uDC00-\uDFFF]|[\u2600-\u27BF]|[#*0-9]\uFE0F?\u20E3|[!"#$%&'()*+,.\/:;<=>?@\[\\\]^_`{|}~]/g, '').replace(/ /g, '-') : '';
					
					
					// .replace(/\s+/g, "-").toLowerCase().replace(/[^\w\d\s_-]/g, "").replace(/[-_]+/g, "-").replace(/^-+|-+$/g, "").replace(/[\p{Emoji}\u200B-\u200D\uFE0F\u2B50\u20E3\u2122\u00AE]/gu, "");

					/* // Convert spaces to dashes
					.replace(/\s+/g, '-')
					// Convert uppercase characters to lowercase (for any language's characters)
					.toLowerCase()
					// Remove all punctuation except for dashes (-) and underscores (_)
					.replace(/[^\w\s_-]/g, '')
					// Remove emojis and special characters
					.replace(/[\p{Emoji}\u200B-\u200D\uFE0F\u2B50\u20E3\u2122\u00AE]/gu, '')
					// Normalize multiple dashes or underscores into a single dash
					.replace(/[-_]+/g, '-')
					// Trim leading or trailing dashes not used, as VS Code does not do that!
					.replace(/^-+|-+$/g, ''); */
		
					// TODO: check if .replace(/^[^\p{L}]*/u, "") works with Qt.
					// also remove `[]` from the Link text, as if messes with the regex. 
                    
					// Ensure parentheses `( )` remain properly encoded
                    link = link.replace(/\(/g, "%28").replace(/\)/g, "%29");
                    fragment = fragment.replace(/\(/g, "%28").replace(/\)/g, "%29");

                    // Construct the final markdown link
                    var result = prefix + "[" + text + "](" + link;
                    if (fragment.length > 0) {
                        result += "#" + fragment;
                    }
                    if (title.length > 0) {
                        result += " " + title;
                    }
                    result += ")";

                    return result;
                });  // end of producedashedlinksfuntion
				
                // Restore the original code blocks
                markdown = markdown.replace(/<<<CODE_BLOCK_(\d+)>>>/g, function (match, index) {
                    return codeBlocks[parseInt(index, 10)];
                });

                return markdown;
            }
		
		var noteIds = script.fetchNoteIdsByNoteTextPart("");    //yields numbers: Ids of Notes, seperated by komma: 1,3,2
        
		if (action == "ObsidianImport") {
					
			var counter = 0; 		// counts how many notes were changed
			
			// var noteIds = script.fetchNoteIdsByNoteTextPart("");  created already
			//forEach loop to convert Obsidian links to QN links
			noteIds.forEach(function (noteId,i) {
			var noteobject = script.fetchNoteById(noteId);  // No direct access in the log panel as it creates an object with certain attributes through the QN-API. 
			var noteName = noteobject.name			// Notename of the noteobject
			var fullPath = noteobject.fullNoteFilePath; // this yields the full path
			var text = noteobject.noteText;     // Access notetext of Noteobject
			var originalTextLength = text.length;   // Size of original text.  
			         				
			// function to convert the links and heading fragments of the current note to QOwnNotes/Obsidian style
			function convertObsidianToQNLinks(markdown) {
				// Identify and temporarily replace code blocks. Otherwise there might occur unwanted possible replacements in codeblocks (false positives).
				var codeBlocks = [];
				markdown = markdown.replace(/(```[\s\S]*?```|`[^`]*`)/g, function (match) {
				codeBlocks.push(match);
				return "<<<CODE_BLOCK_" + (codeBlocks.length - 1) + ">>>";
				});
				// Improved regex to correctly handle links with nested parentheses
				markdown = markdown.replace(/(^|[^`])\[([^\]]+)\]\((<)?((?:[^()]+|\([^()]*\))*)(>)?\)/g, function (match, prefix, text, openBracket, url, closeBracket) {
					// Ignore external internet links
					if (/^(https?:\/\/|www\.)/.test(url)) {
						return match;
					}

					var titleMatch = url.match(/(".*")$/);
					var title = titleMatch ? titleMatch[0] : '';
					url = titleMatch ? url.substring(0, url.length - title.length) : url;   // Shorthand Ternary Operator (condition ? expr1 : expr2)   if (condition) expr1 else expr2
					
					// Remove angle brackets `< >` and trim spaces
					url = url.replace(/^<\s*|\s*>$/g, '').trim();
					var urlParts = url.split('#');      //This splits the url into the normal link part [0] and then the link fragment part [1] (everything after "#")
					var link = urlParts[0]; 
					// To link to a heading wihin the same (!) file, QN adds the filename e.g. [name](file.md#heading) instead of [name](#heading). Other editors usally leave the filename blank! Therefore adding the notename as a prefix is crucial! 
					if (link == 0) {
						link = noteName + ".md";
					}
					var fragment = urlParts.length > 1 ? urlParts[1] : '';  //set fragment to empty if there is only one url part 


					// Remove leading './' from relative paths as created by Vs Codium
					if (link.indexOf("./") === 0) {
						link = link.substring(2);		// only take substring starting from the 3rd position
					}

					// Encode the link and fragment properly. "." and "/" will be conserved for readability. 
					link = encodeURIComponent(safeDecodeURI(link)).replace(/%2E/g, ".").replace(/%2F/g, "/");
					fragment = fragment.length > 0 ? encodeURIComponent(safeDecodeURI(fragment)) : '';
					
					// Ensure parentheses `( )` remain properly encoded
					link = link.replace(/\(/g, "%28").replace(/\)/g, "%29");
					fragment = fragment.replace(/\(/g, "%28").replace(/\)/g, "%29");

					// Construct the final markdown link
					var result = prefix + "[" + text + "](" + link;
					if (fragment.length > 0) {
						result += "#" + fragment;
					}
					if (title.length > 0) {
						result += " " + title;		// Add optional markdown title
					}
					result += ")";

					return result;
				});

				// Restore the original code blocks
				markdown = markdown.replace(/<<<CODE_BLOCK_(\d+)>>>/g, function (match, index) {
                        return codeBlocks[parseInt(index, 10)];
                    });
				return markdown;
				} // end of convertObsidianToQNLinks function				
				
				var lengthOfAlteredtext = convertObsidianToQNLinks(noteobject.noteText).length;  
				
				// Improve performance. Only write to file in case something has changed. This works as encodeURIComponent always increases the characterlength. Monotonically increasing function.  
				if (originalTextLength < lengthOfAlteredtext) {               
					counter += 1;
					script.log("File " + noteName + " will be updated to adjust to QOwnNotes Link Style. " + originalTextLength + " oldNotelength vs. newNotelength  " + lengthOfAlteredtext);
					var alteredText = convertObsidianToQNLinks(text);
					script.writeToFile(noteobject.fullNoteFilePath, alteredText); //QN HOOK: saves content to file (filepath, textToBeSaved)	
					//script.noteTextEditWrite(convertObsidianToQNLinks(text)); // Note: This will not work, as it continuosly overwrite only the currently opened note. I do want to change the content of several different notes!
				}
				else {
					script.log("nothing to change in: " + noteName);
				}

			}); //end of Foreach loop
			script.regenerateNotePreview();		// sometimes the editor panel needs time to show changes. Click on a different note. Unfortunately this only changes the preview. Sometime the editor still lags. 
			script.informationMessageBox("<strong>Changed " + counter + " file(s)</strong>. Sucessfully imported markdown links from <strong>Obsidian</strong> to <strong>QOwnNotes</strong> for all files (some files did not need an update, as they may not contain links). See the protocol panel to check for updated filenames. </br> Please <strong>refreh the note</strong> in case changes are not visible, by clicking on a different note and then on the current note again.");
	}
        
		// Import Github flavoured markdown e.g. [note](note.md#heading-with-dashes)
		if (action == "GFMImport") {
            var counter = 0;
			var i;
			var dataarray = [];
			
			//var noteIds = script.fetchNoteIdsByNoteTextPart(""); //already created
			//forEach loop to create the data array structure for storing Index, NoteName, FullNotePath, Headings, PandocstyleHeadings (see "Core Element" down below)
            noteIds.forEach(function (noteId, i) {
            var noteobject = script.fetchNoteById(noteId);
            var noteName = noteobject.name; // name of the current note
            var fullPath = noteobject.fullNoteFilePath; // Note: this yields the full path.
			var text = noteobject.noteText; //selects all text in current note
			
			var codeBlocks = [];
			text = text.replace(/(```[\s\S]*?```|`[^`]*`)/g, function (match) {
				codeBlocks.push(match);
				return "<<<CODE_BLOCK_" + (codeBlocks.length - 1) + ">>>";
			});
			
			const headingRegex = /^(#{1,6})\s+(.*)$/gm; //RegExp to search for all markdown headings
			const headings = []; //array for all found headings in current note
			const pandocStyle = []; //array for all found headings in current note converted to Pandoc/Github style
			var seen = {}; // Definition of an object to check if headings occur more than 1 time  
			let match;

			while ((match = headingRegex.exec(text)) !== null) {
			headings.push(match[2]); // while loop writes the found headings to the headings array
			}

			for (var i=0; i<headings.length; i++) // The for loop is used to convert each heading in the headings array into the correct Pandoc/Github style and to handle duplicate headings in the note
            {
			//Replace all spaces and newlines with hyphens + Convert all alphabetic characters to lowercase. + Remove all footnotes. Note Unicode charaters will be left intact.
			//var baseId = headings[i].toLowerCase().replace(/\[\^([^\]]+)\]/,"").replace(/\[\^[0-9a-z]+\]/,"").trim().replace(/\s+/g,"-").replace(/^[^\p{L}]*/u, ""); 
            //var baseId = headings[i].toLowerCase().replace(/\s+/g, "-").replace(/[^\w\s_-]/g, "").replace(/[-_]+/g, "-").replace(/[\p{Emoji}\u200B-\u200D\uFE0F\u2B50\u20E3\u2122\u00AE]/gu, "");
            //var baseId = headings[i].toLowerCase().replace(/\s+/g, "-").replace(/[^\p{L}\d\s_-]/gu, "").replace(/[-_]+/g, "-").replace(/[\p{Emoji}\u200B-\u200D\uFE0F\u2B50\u20E3\u2122\u00AE]/gu, "");
            //var baseId = headings[i].toLowerCase().replace(/[^\w\d\s_-]/g, "").replace(/[-_]+/g, "-").replace(/^-+|-+$/g, "").replace(/[\p{Emoji}\u200B-\u200D\uFE0F\u2B50\u20E3\u2122\u00AE]/gu, "");
            //var baseId = headings[i].toLowerCase().replace(/[^\p{L}\p{N}\s\-]/gu, '').replace(/\s+/g, '-').replace(/^-+|-+$/g, '');
            //var baseId = headings[i].toLowerCase().replace(/[^\p{L}\p{N}\-]/gu, '-').replace(/^-+|-+$/g, '');
            //var baseId = headings[i].toLowerCase().replace(/[^a-z0-9\-]/g, '-').replace(/^-+|-+$/g, '');
            //var baseId = headings[i].toLowerCase().replace(/[^\p{L}\p{N}\s-]/gu, '-');
            //var baseId = headings[i].toLowerCase().replace(/[\uD800-\uDBFF][\uDC00-\uDFFF]|[\u2600-\u27BF]|[#*0-9]\uFE0F?\u20E3|[!-\/:-@[-`{-~]/g, '').trim().replace(/\s+/g, '-').replace(/-+/g, '-').replace(/^-+|-+$/g, '');
            //var baseId = headings[i].toLowerCase().replace(/[\uD800-\uDBFF][\uDC00-\uDFFF]|[\u2600-\u27BF]|[#*0-9]\uFE0F?\u20E3|[!"#$%&'()*+,.\/:;<=>?@\[\\\]^_`{|}~]/g, '').replace(/\s/g, '-').replace(/-+/g, '-');
            var baseId = headings[i].trim().toLowerCase().replace(/[\uD800-\uDBFF][\uDC00-\uDFFF]|[\u2600-\u27BF]|[#*0-9]\uFE0F?\u20E3|[!"#$%&'()*+,.\/:;<=>?@\[\\\]^_`{|}~]/g, '').replace(/ /g, '-');

				
				if (seen[baseId] !== undefined) {
					seen[baseId]++;
					pandocStyle[i] = baseId + "-" + seen[baseId];
				} 
				else {
					seen[baseId] = 0;
					pandocStyle[i] = baseId;
				}
            }

			// Core element: final data structure including index of note, note name, full path to note, all headings and all pandoc styled headings
			dataarray.push({
				index: i,
				name: noteName,
				path: fullPath,
				headings: headings,
				pandoc: pandocStyle
			});
			
			// Restore the original code blocks
			text = text.replace(/<<<CODE_BLOCK_(\d+)>>>/g, function (match, index) {
			return codeBlocks[parseInt(index, 10)];
                    });
			}); //end foreach loop for creating the data array structure
		   			
			// Start of actual loop to replace links. Before we only created the dataarray. 		
			//var noteIds = script.fetchNoteIdsByNoteTextPart("");		//already created globally
			//forEach loop to convert Obsidian links to QN links
			noteIds.forEach(function (noteId,i) {			// Note-Ids were already created at the beginning of the script
			var noteobject = script.fetchNoteById(noteId);  // No direct access in the log panel as it creates an object with certain attributes through the QN-API. 
			var noteName = noteobject.name			// Notename of the noteobject
			var fullPath = noteobject.fullNoteFilePath; // this yields the full path
			var text = noteobject.noteText;     // Access notetext of Noteobject
			var originalTextLength = text.length;   // Size of original text.  
			
			// decode URL encoding + normalize slashes + remove leading ./
			
			function normalizePath(path) {
				if (!path) return "";
					path = safeDecodeURI(path).replace(/\\/g, "/").replace(/^\.\/+/, "");
				return path;
			}
			
			// This function converts pandoc/github heading fragments [note](note.md#heading-with-dashes) to QOwnNotesStyle heading fragments
			function pandocFragmentToHeading(link, fragment, dataarray, currentNotePath) {

				var decodedLink = normalizePath(link);
				var linkPath    = decodedLink;
				var linkFile    = decodedLink.split("/").pop().replace(/\.md$/i, "");
				
				//access dataarray with for loop to retrieve all noteNames and notePaths
				for (var i = 0; i < dataarray.length; i++) {
					var note = dataarray[i];
					var notePath = normalizePath(note.path);

					// 1️ Strong match: path ending matches
					if (linkPath && notePath && notePath.endsWith(linkPath)) {
						var idx = note.pandoc.indexOf(fragment);
						if (idx !== -1) return note.headings[idx];
					}

					// 2️ Weak fallback: same note (same-file link)
					if (!link && note.path === currentNotePath) {
						var idx = note.pandoc.indexOf(fragment);
						if (idx !== -1) return note.headings[idx];
					}

					// 3️ Weak fallback: same name only (last resort)
					if (note.name === linkFile) {
						var idx = note.pandoc.indexOf(fragment);
						if (idx !== -1) return note.headings[idx];
					}
				}
			return fragment;
			}
			// function to convert dashed links to QOwnNotes links. 
			function convertDashedLinksToQN(markdown) {
					// Identify and temporarily replace code blocks
                    var codeBlocks = [];
					markdown = markdown.replace(/(```[\s\S]*?```|`[^`]*`)/g, function (match) {
						codeBlocks.push(match);
						return "<<<CODE_BLOCK_" + (codeBlocks.length - 1) + ">>>";
					});
5
                    // Improved regex to correctly handle links with nested parentheses
                    markdown = markdown.replace(/(^|[^`])\[([^\]]+)\]\((<)?((?:[^()]+|\([^()]*\))*)(>)?\)/g, function (match, prefix, text, openBracket, url, closeBracket) {
                        // Ignore external internet links
                        if (/^(https?:\/\/|www\.)/.test(url)) {
                            return match;
                        }

                    var titleMatch = url.match(/(".*")$/);
					var title = titleMatch ? titleMatch[0] : '';
					url = titleMatch ? url.substring(0, url.length - title.length) : url;   // Shorthand Ternary Operator (condition ? expr1 : expr2)   if (condition) expr1 else expr2
					
					// Remove angle brackets `< >` and trim spaces
					url = url.replace(/^<\s*|\s*>$/g, '').trim();
					var urlParts = url.split('#');      //This splits the url into the normal link part [0] and then the link fragment part [1] (everything after "#")
					var link = urlParts[0]; 
					// To link to a heading wihin the same (!) file, QN adds the filename e.g. [name](file.md#heading) instead of [name](#heading). Other editors usally leave the filename blank! Therefore adding the notename as a prefix is crucial! 
					if (link == 0) {
						link = noteName + ".md";
					}
					var fragment = urlParts.length > 1 ? urlParts[1] : '';  //set fragment to empty if there is only one url part 

					// Remove leading './' from relative paths as created by Vs Codium
					if (link.indexOf("./") === 0) {
						link = link.substring(2);		// only take substring starting from the 3rd position
					}

                        // Encode the link and fragment properly. "." and "/" will be conserved for readability. 
                        link = encodeURIComponent(safeDecodeURI(link)).replace(/%2E/g, ".").replace(/%2F/g, "/");
                        
						//Start of difference to the convertObsidianToQNLinks function
						// replaced: fragment = fragment.length > 0 ? encodeURIComponent(safeDecodeURI(fragment)) : '';	
						if (fragment.length > 0 ) {
						var originalHeading = pandocFragmentToHeading(
								link,        // link may contain .md → handled inside helper
								fragment,
								dataarray, 
								fullPath
							);						 
							fragment = encodeURIComponent(safeDecodeURI(originalHeading.trim()));		// need .trim() as the heading might have leading space. It would therefore return %20 at the beginning and end!
						}
				
                        // Ensure parentheses `( )` remain properly encoded
                        link = link.replace(/\(/g, "%28").replace(/\)/g, "%29");
                        fragment = fragment.replace(/\(/g, "%28").replace(/\)/g, "%29");

                        // Construct the final markdown link
                        var result = prefix + "[" + text + "](" + link;
                        if (fragment.length > 0) {
                            result += "#" + fragment;
                        }
                        if (title.length > 0) {
                            result += " " + title; // Add optional markdown title
                        }
                        result += ")";

                        return result;
                    });

                    // Restore the original code blocks
                    markdown = markdown.replace(/<<<CODE_BLOCK_(\d+)>>>/g, function (match, index) {
                        return codeBlocks[parseInt(index, 10)];
                    });

                    return markdown;
				} // end function convertDashedLinksToQN
					
				var lengthOfAlteredtext = convertDashedLinksToQN(noteobject.noteText).length;  
				var alteredText = convertDashedLinksToQN(noteobject.noteText); 
				
				// Improve performance. Only write to file in case something has changed.				
				if (alteredText !== text) { 
					counter += 1;	
					script.log("File " + noteName + " will be updated to adjust to QN Link Style. " + originalTextLength + " oldNotelength vs. newNotelength  " + lengthOfAlteredtext);
					script.writeToFile(noteobject.fullNoteFilePath, alteredText); //QN HOOK: saves content to file (filepath, textToBeSaved)
					//script.noteTextEditWrite(convertObsidianToQNLinks(text)); // Note: This will not work, as it continuosly overwrite only the currently opened note. I do want to change the content of several different notes!
				}						
				else {
					script.log("nothing to change in: " + noteName);
				}
		   
			}); //end for each loop
		   
			var allPandocHeadings = dataarray.map(n => n.pandoc); //provide all names with an array. No need for a for loop. 
			//shorthand for :
			//function (n) {
				//return n.pandoc;
			// }
			script.log(allPandocHeadings);
			
			script.informationMessageBox("<strong>Changed " + counter + " file(s)</strong>. Sucessfully imported markdown links from <strong>Github/Markor/Pandocstyle</strong> to <strong>QOwnNotes</strong> for all files (some files did not need an update, as they may not contain links). See the protocol panel to check for updated filenames. Please <strong>refreh the note</strong> in case changes are not visible, by clicking on a different note and then on the current note again.");
        }
		
		// Convert heading fragments in ALL files to Github/Pandoc format [note](note.md#heading-with-dashes)
		if (action == "GFMExportAll") 
        {  
			var counter = 0; 		// counts how many notes were changed
			//var noteIds = script.fetchNoteIdsByNoteTextPart(""); // created globally
			//forEach loop to convert Obsidian links to QN links
			noteIds.forEach(function (noteId,i) {
			var noteobject = script.fetchNoteById(noteId);  // No direct access in the log panel as it creates an object with certain attributes through the QN-API. 
			var noteName = noteobject.name			// Notename of the noteobject
			var fullPath = noteobject.fullNoteFilePath; // this yields the full path
			var text = noteobject.noteText;     // Access notetext of Noteobject
			var originalTextLength = text.length;   // Size of original text.  
			
			var lengthOfAlteredtext = produceDashedLinks(noteobject.noteText).length;  
			var alteredText = produceDashedLinks(text);
			
			if (alteredText !== text) { 
					counter += 1;	
					script.log("File " + noteName + " will be updated to adjust to Github Link Style. " + originalTextLength + " oldNotelength vs. newNotelength  " + lengthOfAlteredtext);
					script.writeToFile(noteobject.fullNoteFilePath, alteredText); //QN HOOK: saves content to file (filepath, textToBeSaved)
					//script.noteTextEditWrite(convertObsidianToQNLinks(text)); // Note: This will not work, as it continuosly overwrite only the currently opened note. I do want to change the content of several different notes!
				}						
			else {
					script.log("nothing to change in: " + noteName);
				}
		
        }); //Endforeach
		
		script.informationMessageBox("<strong>Changed " + counter + " file(s)</strong>. Sucessfully exported markdown links from <strong>QOwnNotes</strong> to <strong>Github/Markor/Pandocstyle</strong> for all files (some files did not need an update, as they may not contain links). See the protocol panel to check for updated filenames. Please <strong>refreh the note</strong> in case changes are not visible, by clicking on a different note and then on the current note again.");
		
		}
		
		if (action == "GFMExportPage") 
        {           
            var text = script.noteTextEditSelectAll();
            text = script.noteTextEditSelectedText(); 
            script.noteTextEditWrite(produceDashedLinks(text));
			script.informationMessageBox("Converted <strong> all links in the current note</strong> into <strong>Github/Markor/Pandocstyle</strong>. Please <strong>refreh the note</strong> in case changes are not visible, by clicking on a different note and then on the current note again.");
		}

        }

}   
