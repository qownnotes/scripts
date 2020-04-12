import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * We add some javascript to the page to let the magic happen.
 * Based on https://stackoverflow.com/a/49041392
 */
Script {
    function noteToMarkdownHtmlHook(note, html) {
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
