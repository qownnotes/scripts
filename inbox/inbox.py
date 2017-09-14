#!/usr/bin/env python

import os
import re
import sys
import time
import argparse
import collections
import multiprocessing.dummy

import md_link
import md_convert
import safe_path

try:
    import watchdog.events
    import watchdog.observers
except ImportError:
    pass


File_attrs = collections.namedtuple('File_attrs', 'file_path folder_dir_path output_dir_path output_file')
"""
A named tuple which functions use to pass input data - data of files to be processed
:param file_path: full absolute path to the file to process
:param folder_dir_path: full absolute path to directory where 'media' and 'attachment' directories are
:param output_dir_path: full absolute path to directory where resulting text file will be stored
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


def text_to_md(file_attrs, topic_marker):
    """
    This will process specified text file getting its topics and replacing urls with favicons and titles where possible
    :param file_attrs: File_attrs named tuple
    :param topic_marker: symbol(s) which start the 'topic' word, if such word present in text, it will go to 'topic.md'
    :return: list of Note_attrs named tuple
    """
    filename = os.path.splitext(os.path.basename(file_attrs.file_path))[0]
    mtime = time.localtime(os.path.getmtime(file_attrs.file_path))

    try:
        with open(file_attrs.file_path, 'r') as text_file:
            text = text_file.read()
    except UnicodeDecodeError:
        return

    topics = re.findall(topic_marker + '(\w*)', text)
    text = re.sub(topic_marker + '\w*[ ]?', '', text).strip()

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


def make_flat_list(mixed_list, target_item_type=tuple):
    """
    Make a list that has lists and 'target_item_type' as items flat, not recursive.
    :param mixed_list: list to make flat
    :param target_item_type: type of items in the flat list
    :return: flat list of 'target_item_type'
    """
    flat_list = []
    for obj in mixed_list:
        if type(obj) == list:
            for item in obj:
                if type(item) == target_item_type:
                    flat_list.append(item)
        elif type(obj) == target_item_type:
            flat_list.append(obj)
    return flat_list


def process_by_path(file_path):
    """
    Checks if the file is valid for processing and returns File_attrs tuple depending on its path
    :param file_path: Absolute file path
    :return: File_attrs named tuple
    """
    if file_path.endswith(('.md', 'notes.sqlite')) \
    or file_path.startswith((folder_dir + os.sep + 'media', folder_dir + os.sep + 'attachments')) \
    or os.sep + '.' in file_path[len(folder_dir):] \
    or '_files' + os.sep in file_path[len(folder_dir):]:
        return

    if file_path[:len(inbox_dir)] == inbox_dir:
        if os.path.dirname(file_path) == inbox_dir:
            return File_attrs(file_path=file_path, folder_dir_path=folder_dir,
                              output_dir_path=inbox_dir, output_file='')
        else:
            return File_attrs(file_path=file_path, folder_dir_path=folder_dir,
                              output_dir_path=inbox_dir,
                              output_file=os.path.dirname(file_path)[len(inbox_dir)+1:].replace(os.sep, ' - ') + '.md')
    else:
        return File_attrs(file_path=file_path, folder_dir_path=folder_dir,
                          output_dir_path=os.path.dirname(file_path), output_file='*no mtime*')


def process_by_ext(file_attrs):
    """
    This will run different functions to process specified File_attrs tuple based on file extension
    :param file_attrs: File_attrs named tuple
    :return: Note_attrs named tuple
    """
    if file_attrs.file_path.endswith('.txt') or not os.path.splitext(file_attrs.file_path)[1]:
        return text_to_md(file_attrs, args.topic_marker)
    elif args.pandoc_bin and args.pandoc_ver and file_attrs.file_path.endswith(('.htm', '.html')):
        return html_to_md(file_attrs, args.pandoc_bin, args.pandoc_ver)
    elif file_attrs.file_path.endswith(('.jpg', '.png', '.gif')):
        return file_to_md(file_attrs, 'media')
    else:
        return file_to_md(file_attrs, 'attachments')


def write_note_and_delete(note_attrs):
    """
    Create or append existing note files based on Note_attrs tuples data, then delete the source file
    :param note_attrs: Note_attrs named tuple
    """
    if os.path.isfile(note_attrs.output_file_path):
        if os.path.dirname(note_attrs.output_file_path) == inbox_dir:
            note_file_path = note_attrs.output_file_path
            with open(note_file_path, 'r') as source:
                content = note_attrs.mtime + note_attrs.text + '\n\n' + source.read()
        else:
            i = 1
            while os.path.isfile(os.path.splitext(note_attrs.output_file_path)[0] + '_' + str(i) + '.md'):
                i += 1
            note_file_path = os.path.splitext(note_attrs.output_file_path)[0] + '_' + str(i) + '.md'
            content = note_attrs.mtime + note_attrs.text
    else:
        note_file_path = note_attrs.output_file_path
        if note_attrs.title:
            content = note_attrs.title + note_attrs.text
        else:
            content = note_attrs.mtime + note_attrs.text

    with open(note_file_path, 'w') as output:
        output.write(content)

    if os.path.isfile(note_file_path):
        try:
            os.remove(note_attrs.input_file_path)
        except OSError:
            pass


if __name__ == '__main__':

    script_path = os.path.dirname(sys.argv[0])

    for file in os.listdir(script_path):
        if file[-5:] == '.lock':
            os.remove(script_path + os.sep + file)

    lockfile_path = script_path + os.sep + str(int(time.time())) + '.lock'
    open(lockfile_path, 'w').close()

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
    arg_parser.add_argument('-w', '--watch', action='store_true', dest='watch_fs', required=False,
                            help="Watch and process new files as they appear after initial scan")
    args = arg_parser.parse_args()

    inbox_dir = args.inbox_dir
    folder_dir = args.folder_dir

    os.makedirs(inbox_dir, exist_ok=True)
    os.makedirs(folder_dir + os.sep + 'media', exist_ok=True)
    os.makedirs(folder_dir + os.sep + 'attachments', exist_ok=True)

    if args.scan_folder:
        scan_path = folder_dir
    else:
        scan_path = inbox_dir

    file_list = []
    for root, subdirs, files in os.walk(scan_path):
        for file_path in sorted([root + os.sep + file for file in files], key=os.path.getmtime):
            file_attrs = process_by_path(file_path)
            if file_attrs:
                file_list.append([file_attrs])

    write_list = multiprocessing.dummy.Pool(100).starmap(process_by_ext, file_list)

    flat_write_list = make_flat_list(write_list, Note_attrs)

    for note_attrs in flat_write_list:
        write_note_and_delete(note_attrs)

    if args.watch_fs:

        try:
            import watchdog.events
            import watchdog.observers
        except ImportError:
            print("Can't find Watchdog module. Watching for changes won't work.")
            exit(1)


        class FsEventHandler(watchdog.events.FileSystemEventHandler):
            def on_any_event(self, event):
                if event.is_directory:
                    return
                elif event.event_type == 'created':
                    file_path = event.src_path
                elif event.event_type == 'moved':
                    file_path = event.dest_path
                else:
                    return

                file_attrs = process_by_path(file_path)

                if file_attrs:
                    # Wait for all the web page resources saved/synced
                    if file_path.endswith(('.htm', '.html')):
                        time.sleep(2)
                    obj_to_write = process_by_ext(file_attrs)
                else:
                    return

                if type(obj_to_write) == list:
                    for note_attrs in obj_to_write:
                        write_note_and_delete(note_attrs)
                else:
                    write_note_and_delete(obj_to_write)


        event_handler = FsEventHandler()
        observer = watchdog.observers.Observer()
        observer.schedule(event_handler, scan_path, recursive=True)
        observer.start()

        try:
            while True:
                if os.path.isfile(lockfile_path):
                    time.sleep(5)
                else:
                    raise Exception
        except:
            observer.stop()

        observer.join()
