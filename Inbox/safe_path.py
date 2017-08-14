import platform


def filename(filename):
    """
    Replace the characters in file name that are not allowed in current OS
    :param filename: file name
    :return: file name which is safe to use in current OS
    """
    if platform.system() == 'Linux':
        safe_filename = filename.replace('/', '-')
    elif platform.system() == 'Darwin':
        safe_filename = filename.replace('/', '-').replace(':', '-')
    else:
        safe_filename = filename
        for char in (':', '/', '\\', '|'):
            safe_filename = safe_filename.replace(char, '-')
        for char in ('?', '*'):
            safe_filename = safe_filename.replace(char, '')
        safe_filename = safe_filename.replace('<', '(')
        safe_filename = safe_filename.replace('>', ')')
        safe_filename = safe_filename.replace('"', "'")

    return safe_filename