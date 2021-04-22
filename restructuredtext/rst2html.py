
import os
import binascii

from docutils.core import publish_string
from docutils.parsers.rst import states, directives
from cloud_sptheme.ext import table_styling


class MyExtendedRSTTable(table_styling.ExtendedRSTTable):
    @property
    def config(self):
        return states.Struct(
            table_styling_default_align='right',
            table_styling_class='styled-table',
            html_theme='clound')

directives.register_directive('extable', MyExtendedRSTTable)

# see http://docutils.sourceforge.net/docs/user/config.html
default_rst_opts = {
    'no_generator': True,
    'no_source_link': True,
    'tab_width': 4,
    'file_insertion_enabled': False,
    'raw_enabled': False,
    'stylesheet_path': None,
    'traceback': True,
    'halt_level': 5,
    'syntax_highlight': 'short',
}


def rst2html(rst, theme=None, opts=None):
    rst_opts = default_rst_opts.copy()
    # if opts:
    #     rst_opts.update(opts)
    # rst_opts['template'] = 'var/themes/template.txt'
    #
    # stylesheets = ['basic.css', 'pygments-default.css']
    # if theme:
    #     stylesheets.append('%s/%s.css' % (theme, theme))
    # rst_opts['stylesheet'] = ','.join([J('var/themes/', p) for p in stylesheets ])

    curdir = os.path.dirname(__file__)
    rst_opts['template'] = os.path.join(curdir, 'template.txt')
    stylesheets = [
        os.path.join(curdir, 'basic.css'),
        os.path.join(curdir, 'darcula.css'),
        os.path.join(curdir, 'misc.css'),
        table_styling.css_path
    ]
    rst_opts['stylesheet'] = ','.join(stylesheets)

    out = publish_string(rst, writer_name='html', settings_overrides=rst_opts)
    print(binascii.hexlify(out).decode())

