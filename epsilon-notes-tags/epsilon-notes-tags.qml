import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * After enabling this script internal QOwnNotes tag data will be lost !!!
 * 
 * This script makes QOwnNotes read and write note tags to YAML section before note text.
 * This makes tags compatible with Epsilon Notes app for Android. 
 * 
 * The YAML section must start at the first line of the note. 
 * YAML format for tags is:
 * ---
 * tags: tag1 tag2 multi_word_tag
 * ...
 */

Script {
    property bool useDashesForClosing

    property variant settingsVariables: [
        {
            "identifier": "useDashesForClosing",
            "name": "",
            "description": "Use three dashes as YAML closer for front matter created by the script",
            "type": "boolean",
            "default": "false",
        },
    ]
    
    /**
     * Handles note tagging for a note
     *
     * This function is called when tags are added to, removed from or renamed in
     * a note or the tags of a note should be listed
     *
     * @param note
     * @param action can be "add", "remove", "rename" or "list"
     * @param tagName tag name to be added, removed or renamed
     * @param newTagName tag name to be renamed to if action = "rename"
     * @return string or string-list (if action = "list")
     */
    
    function noteTaggingHook(note, action, tagName, newTagName) {
        const noteText = note.noteText
        var noteYaml = null
        var tagLine = null
        var yamlTags = []
        
        if (noteText.substring(0, 4) == '---\n') {
            var yamlEndIndex = noteText.indexOf('\n...\n')
            
            // If there's no proper "..." YAML ending "---" is recognized as one
            if (yamlEndIndex == -1)
                yamlEndIndex = noteText.indexOf('\n---\n')
        
            if (yamlEndIndex != -1) {
                noteYaml = noteText.substring(0, yamlEndIndex)
                
                const tagLineMatch = noteYaml.match(/^tags:(.*)/m)
                
                if (tagLineMatch != null) {
                    const tagLineStartIndex = tagLineMatch.index
                    const tagLineEndIndex = tagLineStartIndex + tagLineMatch[0].length
                    tagLine = tagLineMatch[0]
                    yamlTags = tagLineMatch[1].trim().split(' ')
                }
            }
        }
            
        switch (action) {
            // adds the tag "tagName" to the note
            // the new note text has to be returned so that the note can be updated
            // returning an empty string indicates that nothing has to be changed
            case 'add':
                tagName = tagName.trim()
                tagName = tagName.replace(/ /g, '_')
                
                if (yamlTags.indexOf(tagName) != -1)
                    return
                
                // For some reason newly created JS/QML arrays contain an empty item 
                if (yamlTags[0] == '')
                    yamlTags.shift()
                
                yamlTags.push(tagName)
                yamlTags.sort()
                
                if (useDashesForClosing)
                    var yamlCloser = '\n---\n\n'
                else
                    var yamlCloser = '\n...\n\n'
                    
                if (noteYaml == null)
                    return '---\ntags: ' + tagName + yamlCloser + noteText
                else if (tagLine == null)
                    return noteText.substring(0, 4) + 'tags: ' + tagName + '\n' + noteText.substring(4)
                else
                    return noteText.substring(0, tagLineStartIndex) +
                           'tags: ' + yamlTags.join(' ') +  noteText.substring(tagLineEndIndex)
            ;
                    
            // removes the tag "tagName" from the note
            // the new note text has to be returned so that the note can be updated
            // returning an empty string indicates that nothing has to be changed
            case 'remove':
                tagName = tagName.replace(/ /g, '_')
                
                if (yamlTags.indexOf(tagName) == -1)
                    return
                
                yamlTags.splice(yamlTags.indexOf(tagName), 1)
                
                return noteText.substring(0, tagLineStartIndex) +
                       'tags: ' + yamlTags.join(' ') +  noteText.substring(tagLineEndIndex)
            ;

            // renames the tag "tagName" in the note to "newTagName"
            // the new note text has to be returned so that the note can be updated
            // returning an empty string indicates that nothing has to be changed
            case 'rename':
                tagName = tagName.replace(/ /g, '_')
                newTagName = newTagName.replace(/ /g, '_')
                
                if (yamlTags.indexOf(tagName) == -1)
                    return
                
                yamlTags.splice(yamlTags.indexOf(tagName), 1)
                yamlTags.push(newTagName)
                yamlTags.sort()
                
                return noteText.substring(0, tagLineStartIndex) +
                       'tags: ' + yamlTags.join(' ') +  noteText.substring(tagLineEndIndex)
            ;
                
            // returns a list of all tag names of the note
            case 'list':
                if (yamlTags != null) {
                    var tagNameList = []
                    yamlTags.forEach(function(tagName, index, array) {
                        tagName = tagName.replace(/_/g, ' ')
                        if (tagName != '' && tagNameList.indexOf(tagName) == -1) 
                            tagNameList.push(tagName)
                        })
                }
                    
                return tagNameList
            ;
        }
    
        return ''
    }
    
    // Exclude YAML from note preview
    function noteToMarkdownHtmlHook(note, html) {

        if (note.noteText.substring(0, 4) == '---\n') {
                 
            // For ---/nYAML/n.../nNote text
            var yamlEndIndex = html.indexOf('\n...\n')
            
            // For ---/nYAML/n.../n/nNote text
            if (yamlEndIndex == -1)
                yamlEndIndex = html.indexOf('\n...</p>')
                
            if (yamlEndIndex != -1)
                return html.substring(yamlEndIndex+4)
            
            // For ---/nYAML/n---/nNote text
            return html.replace(/\<hr\/\>(\n|.)*?\<h2 id=\"toc_0\"\>(\n|.)*?\<\/h2\>/, '')
        }
    }
}
