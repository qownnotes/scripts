import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * Based on the epsilon-notes script from @Maboroshy.
 * After enabling this script internal QOwnNotes tag data will be lost!
 *
 * This script makes QOwnNotes read and write note tags to YAML section before note text.
 * This makes tags independent from the Markdown editor.
 *
 * Nested tags are supported with a custom separator (default '/').
 *
 * The YAML section must start at the first line of the note.
 * YAML format for tags is:
 * ---
 * tags: tag1 multi_word_tag /nested/tag
 * --- or ...
 */

Script {
    property bool debug
    property variant settingsVariables: [
        {
            "identifier": "useDashesForClosing",
            "name": "",
            "description": "Use three dashes as YAML closer for front matter created by the script",
            "type": "boolean",
            "default": "true"
        },
        {
            "identifier": "tagHierarchySeparator",
            "name": "",
            "description": "Set the separating character for tag hierarchy. \nWarning: '/' is allowed in tag names, so don't use it in tag names or change it to something else.",
            "type": "string",
            "default": "/"
        },
    ]
    property string tagHierarchySeparator
    property bool useDashesForClosing

    /**
   * Fetches the tag hierarchy
   * @param tag
   * @param ancestorsOnly
   */
    function getTagHierarchy(tag, ancestorsOnly = false) {
        var tagHierarchy = tag.name;
        if (tag.parentId !== 0) {
            // better performance
            var tagList = tag.getParentTagNames().reverse();
            if (!ancestorsOnly)
                tagList.push(tag.name);
            tagHierarchy = tagList.join(tagHierarchySeparator);
        } else {
            // root element
            if (ancestorsOnly) {
                return "";
            }
        }
        return tagHierarchy;
    }
    function init() {
        log("init");
    }
    function log(txt) {
        debug = true;
        if (debug) {
            script.log("[yaml tags] " + txt);
        }
    }

    /**
   * Handles note tagging for a note
   *
   * This function is called when tags are added to, removed from or renamed in
   * a note or the tags of a note should be listed
   *
   * @param note
   * @param action can be "add", "remove", "rename" or "list"
   * @param tag to be added, removed or renamed
   * @param newTagName tag name to be renamed to if action = "rename"
   * @return note text string or string-list of tag ids (if action = "list")
   */
    function noteTaggingByObjectHook(note, action, tag, newTagName) {
        var tagHierarchy = getTagHierarchy(tag);
        var noteText = note.noteText;
        var noteYaml = null;
        var tagLine = null;
        var yamlTags = [];

        var yamlCloser = "...";
        if (useDashesForClosing) {
            yamlCloser = "---";
        }

        const regex_space = / /g;
        const yamlHeader = `---\ntags:\n${yamlCloser}\n`;
        const regex_yaml_header = /^(---)[\r\n]*?(tags:)\s*(.*)[\r\n]*?(---|\.\.\.)/; // g0: full match, g1: ---, g2: "tags:", g3: tags, g4: yaml ending

        if (!regex_yaml_header.test(noteText)) {
            noteText = yamlHeader + noteText;
        }
        var match = noteText.match(regex_yaml_header);
        yamlTags = match[3].trim().split(' ');

        function updateNoteText(nText, tagsArray) {
            var newTags = tagsArray.join(' ');
            nText = nText.replace(regex_yaml_header, `$1\n$2 ${newTags}\n$4`);
            return nText;
        }

        switch (action) {
        // adds the tag "tagHierarchy" to the note
        // the new note text has to be returned so that the note can be updated
        // returning an empty string indicates that nothing has to be changed
        case 'add':
            tagHierarchy = tagHierarchy.trim();
            tagHierarchy = tagHierarchy.replace(regex_space, '_');
            // tag already present
            if (yamlTags.indexOf(tagHierarchy) !== -1)
                return;
            yamlTags.push(tagHierarchy);
            yamlTags.sort();
            return updateNoteText(noteText, yamlTags);

        // removes the tag "tagName" from the note
        // the new note text has to be returned so that the note can be updated
        // returning an empty string indicates that nothing has to be changed
        case 'remove':
            tagHierarchy = tagHierarchy.replace(regex_space, '_');
            if (yamlTags.indexOf(tagHierarchy) === -1) {
                return;
            }
            yamlTags.splice(yamlTags.indexOf(tagHierarchy), 1); // remove index of tag
            return updateNoteText(noteText, yamlTags);

        // renames the tag "tagName" in the note to "newTagName"
        // the new note text has to be returned so that the note can be updated
        // returning an empty string indicates that nothing has to be changed
        case 'rename':
            var newTagHierarchy = getTagHierarchy(tag, true); // just the ancestor tree
            newTagHierarchy = newTagHierarchy.replace(regex_space, '_');
            tagHierarchy = tagHierarchy.replace(regex_space, '_');
            newTagName = newTagName.replace(regex_space, '_');

            if (newTagHierarchy.length === 0) {
                // root tag was renamed -> no leading separator needed
                newTagHierarchy = newTagName;
            } else {
                newTagHierarchy += tagHierarchySeparator + newTagName; // build the new tag hierarchy
            }

            yamlTags.forEach(function (tags, i, array) {
                if (tags.startsWith(tagHierarchy)) {
                    array[i] = array[i].replace(tagHierarchy, newTagHierarchy);
                }
            });
            // tag1 tag2 tag2/subtag/3rdsub2
            // find the old hierarchy and replace it with the new one
            yamlTags.sort();
            return updateNoteText(noteText, yamlTags);

        // returns a list of all tag ids of the note
        // animals/mammals/dogs -> returns dogs id
        case 'list':
            var tagIdList = [];
            if (yamlTags !== null && yamlTags.length > 0) {
                // prevent creation of empty tag names ('')
                yamlTags.forEach(function (tagHierarchy, index, array) {
                    tagHierarchy = tagHierarchy.replace(/_/g, ' ');
                    //tagHierarchy = tagName.split('/').slice(-1) // get the last child of the family
                    tag = script.getTagByNameBreadcrumbList(tagHierarchy.split(tagHierarchySeparator)); //  fetches or creates a tag by its "breadcrumb list"
                    if (tag.name !== '' && tagIdList.indexOf(tag.id) === -1)
                        tagIdList.push(tag.id);
                });
            }
            return tagIdList;
        }

        return '';
    }

    // Exclude YAML from note preview
    function noteToMarkdownHtmlHook(note, html, forExport) {
        if (note.noteText.substring(0, 4) === '---\n') {

            // For ---/nYAML/n.../nNote text
            var yamlEndIndex = html.indexOf('\n...\n');

            // For ---/nYAML/n.../n/nNote text
            if (yamlEndIndex === -1)
                yamlEndIndex = html.indexOf('\n...</p>');

            if (yamlEndIndex !== -1)
                return html.substring(yamlEndIndex + 4);

            // For ---/nYAML/n---/nNote text
            return html.replace(/\<hr\/\>(\n|.)*?\<h2 id=\"toc_0\"\>(\n|.)*?\<\/h2\>/, '');
        }
    }
}
