import re
import os
import shutil
import subprocess
import urllib.parse
import distutils.version


def html_text(html_text, pandoc_bin='pandoc', pandoc_ver='1.19.1'):
    """
    This will convert html_text to markdown by running pandoc_bin and return markdown text
    :param html_text: html text to convert
    :param pandoc_bin: command/path to run pandoc
    :param pandoc_ver: pandoc version as string to use appropriate set of options
    :return: converted markdown text
    """
    if distutils.version.LooseVersion(pandoc_ver) < distutils.version.LooseVersion('1.16'):
        pandoc_args = [pandoc_bin, '-f', 'html', '-t', 'markdown_strict+pipe_tables-raw_html', '--no-wrap']
    elif distutils.version.LooseVersion(pandoc_ver) < distutils.version.LooseVersion('1.19'):
        pandoc_args = [pandoc_bin, '-f', 'html', '-t', 'markdown_strict+pipe_tables-raw_html', '--wrap=none']
    else:
        pandoc_args = [pandoc_bin, '-f', 'html', '-t', 'markdown_strict+pipe_tables-raw_html', '--wrap=none',
                       '--atx-headers']

    # Remove firefox reader mode panel if there's one
    html_text = re.sub('<ul id="reader-toolbar" class="toolbar">.*</li></ul></ul>', '', html_text, flags=re.DOTALL)  ## TODO Maybe use html.parser 

    try:
        pandoc_pipe = subprocess.Popen(pandoc_args, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        md_text = pandoc_pipe.communicate(input=html_text.encode('utf-8'))[0].decode('utf-8')
    except:
        return

    return md_text

def saved_html(html_path, folder_dir_path, pandoc_bin='pandoc', pandoc_ver='1.19.1'):
    """
    This will convert html_text to markdown by running pandoc_bin and return markdown text
    I will also move all in-line images to media directory at folder_dir_path and correct the links accordingly
    :param html_path: full absolute path to saved html file to convert, with '_files' dir at the same directory
    :param folder_dir_path: full absolute path to directory where 'media' directory is
    :param pandoc_bin: command/path to run installed pandoc
    :param pandoc_ver: pandoc version to use appropriate set of options
    :return:
    """
    with open(html_path, 'r') as html:
        md_text = html_text(html.read(), pandoc_bin, pandoc_ver)

    if not md_text:
        return

    image_links = re.findall('!\[[^]]*] *\(([^)]*)', md_text)  # TODO What if folder name has brackets
    for link in image_links:
        link_path_tuple = os.path.split(urllib.parse.unquote(link))
        file_path = os.path.join(os.path.dirname(html_path), *link_path_tuple)
        new_file_path = os.path.join(folder_dir_path, 'media', *link_path_tuple)
        new_link_path = 'file://media/' + '/'.join(link_path_tuple)

        md_text = md_text.replace(link, new_link_path)

        try:
            os.makedirs(os.path.dirname(new_file_path), exist_ok=True)
            os.rename(file_path, new_file_path)
        except OSError:
            pass

    shutil.rmtree(os.path.splitext(html_path)[0] + '_files', True)

    return md_text
