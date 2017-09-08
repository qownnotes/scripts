#!/usr/bin/env python

import os
import re
import time
import argparse
import platform
import collections
import multiprocessing.dummy

import md_link
import md_convert
import safe_path


def text_to_md(file_attrs):
    """
    This will process specified text file getting its topics and replacing urls with favicons and titles where possible
    :param file_attrs: File_attrs named tuple
    :return: list of Note_attrs named tuple
    """
    filename = os.path.splitext(os.path.basename(file_attrs.file_path))[0]
    mtime = time.localtime(os.path.getmtime(file_attrs.file_path))

    try:
        with open(file_attrs.file_path, 'r') as text_file:
            text = text_file.read()
    except(UnicodeDecodeError):
        return

    topics = re.findall(file_attrs.topic_marker + '(\w*)', text)
    text = re.sub(file_attrs.topic_marker + '\w*[ ]?', '', text).strip()

    if re.match('^http[s]?://[^\s]*$', text):
        is_bookmark = True
    else:
        is_bookmark = False

    for link in re.findall('(^|\s)(http[s]?://.*)(\s|$)', text, re.MULTILINE | re.IGNORECASE):
        url = md_link.URL(link[1], file_attrs.folder_dir_path)
        text = text.replace(link[1], url.md)
        if is_bookmark:
            bookmark_title = url.title

    if file_attrs.output_file and file_attrs.output_file != '*no mtime*':
        output_files = [file_attrs.output_file]
        headline_title = ''
    elif topics:
        output_files = [topic + '.md' for topic in topics]
        headline_title = ''
    elif is_bookmark:
        headline_title = '# {}\n'.format(bookmark_title)
        if file_attrs.output_file == '*no mtime*':
            output_files = [bookmark_title + '.md']
        else:
            output_files = [time.strftime('%m-%d %H:%M', mtime) + ' ' + bookmark_title + '.md']
    else:
        headline_title = '# {}\n'.format(filename)
        if file_attrs.output_file == '*no mtime*':
            output_files = [filename + '.md']
        else:
            output_files = [time.strftime('%m-%d %H:%M', mtime) + ' ' + filename + '.md']

    output = []
    for output_file in output_files:
        output.append(Note_attrs(input_file_path=file_attrs.file_path,
                                 output_file_path=file_attrs.output_dir_path + os.sep + safe_path.filename(output_file),
                                 text=text,
                                 mtime='**{}**  \n'.format(time.strftime('%x %a %X', mtime)),
                                 title=headline_title))
    return output

def html_to_md(file_attrs, pandoc_bin='pandoc', pandoc_ver=''):
    """
    This will move specified convert specified html file to markdown and move all in-line images to sub-folder at media directory
    :param file_attrs: File_attrs named tuple
    :return: Note_attrs named tuple
    """
    html_file_name_noext = os.path.splitext(os.path.basename(file_attrs.file_path))[0]
    mtime = time.localtime(os.path.getmtime(file_attrs.file_path))
    md_text = md_convert.saved_html(file_attrs.file_path, file_attrs.folder_dir_path,
                                    pandoc_bin=pandoc_bin, pandoc_ver=pandoc_ver)
    if not md_text:
        return

    return Note_attrs(input_file_path=file_attrs.file_path,
                      output_file_path=file_attrs.output_dir_path + os.sep + safe_path.filename(html_file_name_noext + '.md'),
                      text=md_text,
                      mtime='**{}**  \n'.format(time.strftime('%x %a %X', mtime)),
                      title='')

def file_to_md(file_attrs, media_dir_name):
    """
    This will move specified file to media_dir_name and put note with a reference to that file instead
    :param file_attrs: File_attrs named tuple
    :param media_dir_name: name of sub-directory in folder_dir_path where file will be moved (for non-text files)
    :return: Note_attrs named tuple
    """
    mtime = time.localtime(os.path.getmtime(file_attrs.file_path))
    new_filename = str(time.mktime(mtime))[:-2] + '_' + os.path.basename(file_attrs.file_path)
    new_path = os.path.join(file_attrs.folder_dir_path, media_dir_name, new_filename)

    try:
        os.rename(file_attrs.file_path, new_path)
    except OSError:
        pass

    file = md_link.File(new_path, file_attrs.folder_dir_path, os.path.splitext(os.path.basename(file_attrs.file_path))[0])

    if file_attrs.output_file == '*no mtime*':
        output_file = file.title + '.md'
    elif file_attrs.output_file:
        output_file = file_attrs.output_file
    else:
        output_file = time.strftime('%m-%d %H:%M', mtime) + ' ' + file.title + '.md'

    return Note_attrs(input_file_path=file_attrs.file_path,
                      output_file_path=file_attrs.output_dir_path + os.sep + safe_path.filename(output_file),
                      text=file.md,
                      mtime='**{}**  \n'.format(time.strftime('%x %a %X', mtime)),
                      title='# {}\n'.format(file.title))


if __name__ == '__main__':

    File_attrs = collections.namedtuple('File_attrs', 'file_path folder_dir_path output_dir_path topic_marker output_file')
    """
    A named tuple which functions use to pass input data - data of files to be processed
    :param file_path: full absolute path to the file to process
    :param folder_dir_path: full absolute path to directory where 'media' and 'attachment' directories are
    :param output_dir_path: full absolute path to directory where resulting text file will be stored
    :param topic_marker: symbol(s) which start the 'topic' word (for text files)
    :param output_file: empty for new standalone text file with mtime in the name, 
                        '*no mtime*' for or new standalone text file without mtime in the name
                        or full absolute path to the text file which will be appended with a new entry
    """

    Note_attrs = collections.namedtuple('Note_attrs', 'input_file_path output_file_path text mtime title')
    '''A named tuple which functions use to pass output data - data of notes to be written.
    :param input_file_path: full absolute path to the file which was processed to this tuple
    :param output_file_path: full absolute path to the output text file which should be written
    :param text: content of the text file which should be written
    :param mtime: modification time of input file as markdown headline to optionally prepend a text
    :param title: title of a input file as markdown headline to optionally prepend a text'''

    def process_by_ext(file_attrs):
        """
        This will run different functions to process specified File_attrs tuple based on file extension
        :param file_attrs: File_attrs named tuple
        :return: Note_attrs named tuple
        """
        # print(file_attrs.file_path)
        if file_attrs.file_path.endswith('.txt') or not os.path.splitext(file_attrs.file_path)[1]:
            return text_to_md(file_attrs)
        elif args.pandoc_bin and args.pandoc_ver and file_attrs.file_path.endswith(('.htm', '.html')):
            return html_to_md(file_attrs, args.pandoc_bin, args.pandoc_ver)
        elif file_attrs.file_path.endswith(('.jpg', '.png', '.gif')):
            return file_to_md(file_attrs, 'media')
        else:
            return file_to_md(file_attrs, 'attachments')


    arg_parser = argparse.ArgumentParser(description='A script to turn everything in the inbox directory to markdown notes.')
    arg_parser.add_argument('-i', '--inbox', action='store', dest='inbox_dir', required=True,
                        help="Full absolute path to the inbox directory to organize")
    arg_parser.add_argument('-f', '--folder', action='store', dest='folder_dir', required=True,
                        help="Full absolute path to directory where 'media' and 'attachment' directories are")
    arg_parser.add_argument('-m', '--marker', action='store', dest='topic_marker', required=False, default='@',
                        help="Symbol(s) which start the 'topic' word (for text files)")
    arg_parser.add_argument('-s', '--scan-folder', action='store_true', dest='scan_folder', required=False,
                            help="Process whole folder rather than only inbox")
    arg_parser.add_argument('-p', '--pandoc-bin', action='store', dest='pandoc_bin', required=False,
                            help="Command/path to run pandoc")
    arg_parser.add_argument('-pv', '--pandoc-ver', action='store', dest='pandoc_ver', required=False,
                            help="Installed pandoc version")
    args = arg_parser.parse_args()

    inbox_dir = args.inbox_dir
    folder_dir = args.folder_dir
    topic_marker = args.topic_marker

    os.makedirs(inbox_dir, exist_ok=True)
    os.makedirs(folder_dir + os.sep + 'media', exist_ok=True)
    os.makedirs(folder_dir + os.sep + 'attachments', exist_ok=True)

    # Prepare a list of File_attrs tuples for process_by_ext function, based on file location, older files first
    file_list = []
    if args.scan_folder:
        for subfolder, dirs, files in os.walk(folder_dir):
            for file_path in sorted([subfolder + os.sep + file for file in files], key=os.path.getmtime):
                if os.path.isfile(file_path) \
                and not file_path.endswith(('.md', 'notes.sqlite')) \
                and not file_path.startswith((inbox_dir, folder_dir + os.sep + 'media', folder_dir + os.sep + 'attachments')) \
                and os.sep + '.' not in file_path.replace(folder_dir, '') \
                and '_files' + os.sep not in file_path.replace(folder_dir, ''):
                    file_list.append([File_attrs(file_path=file_path, folder_dir_path=folder_dir, output_dir_path=os.path.dirname(file_path),
                                                 topic_marker=topic_marker, output_file='*no mtime*')])

    for file_path in sorted([inbox_dir + os.sep + path for path in os.listdir(inbox_dir)], key=os.path.getmtime):
        if os.path.isdir(file_path) \
        and not os.path.basename(file_path).startswith('.') \
        and not file_path.endswith('_files'):
            for sub_file in sorted([file_path + os.sep + path for path in os.listdir(file_path)], key=os.path.getmtime):
                if not sub_file.endswith('.md') \
                and not os.path.basename(sub_file).startswith('.'):
                    file_list.append([File_attrs(file_path=sub_file, folder_dir_path=folder_dir, output_dir_path=inbox_dir,
                                                 topic_marker=topic_marker, output_file=os.path.basename(file_path) + '.md')])
        else:
            if os.path.isfile(file_path) \
            and not file_path.endswith('.md') \
            and not os.path.basename(file_path).startswith('.'):
                file_list.append([File_attrs(file_path=file_path, folder_dir_path=folder_dir, output_dir_path=inbox_dir,
                                             topic_marker=topic_marker, output_file='')])

    # Run process_by_ext for each File_attrs tuple putting resulting Note_attrs tuples to write_list
    write_list = multiprocessing.dummy.Pool(100).starmap(process_by_ext, file_list)

    # Due to text_to_md outputs list of Note_attrs tuples, this should turn write_list to a flat list
    flat_write_list = []
    for object in write_list:
        if type(object) == list:
            for item in object:
                if type(item) == Note_attrs:
                    flat_write_list.append(item)
        elif type(object) == Note_attrs:
            flat_write_list.append(object)

    # Create or append existing text files based on Note_attrs tuples data
    for note_attrs in flat_write_list:
        try:
            with open(note_attrs.output_file_path, 'r') as source:
                content = note_attrs.mtime + note_attrs.text + '\n\n' + source.read()
        except OSError:
            if note_attrs.title:
                content = note_attrs.title + note_attrs.text
            else:
                content = note_attrs.mtime + note_attrs.text

        with open(note_attrs.output_file_path, 'w') as output:
            output.write(content)

        if os.path.isfile(note_attrs.output_file_path):
            try:
                os.remove(note_attrs.input_file_path)
            except OSError:
                pass

    if platform.system() == 'Linux':
        os.system('notify-send "-a" "Inbox script" "Your inbox is organized"')  # TODO maybe change to gi.repository: Notify