#!/usr/bin/env python

import os
import sys

merge_to_first = sys.argv[1]
delete_merged = sys.argv[2]
note_list = sys.argv[3].split('//>')

note_content_list = []
for note_path in note_list:
    with open(note_path, 'r') as note:
        note_content_list.append(note.read())

if merge_to_first == 'true':
    output_path = note_list.pop(0)
else:
    output_path = "{}{} notes starting with '{}'{}".format(os.path.dirname(note_list[0]) + os.sep,
                                                           len(note_list),
                                                           os.path.splitext(os.path.basename(note_list[0]))[0],
                                                           os.path.splitext(note_list[0])[1])
try:
    with open(output_path, 'w') as output:
        output.write('\n\n'.join(note_content_list))
except:
    pass
else:
    if delete_merged == 'true':
        for note_path in note_list:
            os.remove(note_path)