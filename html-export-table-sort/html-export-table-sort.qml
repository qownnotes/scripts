import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * We add some javascript to the page to let the magic happen.
 * Based on https://stackoverflow.com/a/49041392
 */
Script {
    /**
     * This function is called when the markdown html of a note is generated
     *
     * It allows you to modify this html
     * This is for example called before by the note preview
     *
     * The method can be used in multiple scripts to modify the html of the preview
     *
     * @param {NoteApi} note - the note object
     * @param {string} html - the html that is about to being rendered
     * @param {string} forExport - the html is used for an export, false for the preview
     * @return {string} the modified html or an empty string if nothing should be modified
     */
    function noteToMarkdownHtmlHook(note, html, forExport) {
        html = html.replace("</style>", "th { cursor: pointer; }</style>");
        html = html.replace("</head>", "
        <script>
            document.addEventListener('DOMContentLoaded', (event) => {
                const getCellValue = (tr, idx) => tr.children[idx].innerText || tr.children[idx].textContent;

                const comparer = (idx, asc) => (a, b) => ((v1, v2) =>
                    v1 !== '' && v2 !== '' && !isNaN(v1) && !isNaN(v2) ? v1 - v2 : v1.toString().localeCompare(v2)
                    )(getCellValue(asc ? a : b, idx), getCellValue(asc ? b : a, idx));

                document.querySelectorAll('th').forEach(th => th.addEventListener('click', (() => {
                  const table = th.closest('table');
                  const tbody = table.querySelector('tbody');
                  Array.from(tbody.querySelectorAll('tr'))
                    .sort(comparer(Array.from(th.parentNode.children).indexOf(th), this.asc = !this.asc))
                    .forEach(tr => tbody.appendChild(tr) );
                })));
              });
        </script>
        </head>");
        return html;
    }
}
