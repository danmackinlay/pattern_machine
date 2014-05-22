from config import *


def get_table():
    table_handle = tables.open_file(TABLE_OUT_PATH, 'r')
    return table_handle.get_node('/', 'note_meta')
