#!/usr/bin/env python3
"""Add fictional fixtures to an EMPTY Android emulator; never touch real devices."""
import os
import re
import shlex
import subprocess
from pathlib import Path

adb = Path(os.environ.get('ANDROID_HOME', str(Path.home() / 'Library/Android/sdk'))) / 'platform-tools/adb'
serial = 'emulator-5554'

def shell(*args):
    result = subprocess.run([str(adb), '-s', serial, 'shell', shlex.join(args)],
                            capture_output=True, text=True, check=True)
    if 'Exception' in result.stdout or 'Error' in result.stdout:
        raise RuntimeError(result.stdout)
    return result.stdout

if shell('getprop', 'ro.kernel.qemu').strip() != '1':
    raise SystemExit('Refusing to write: target is not an emulator.')
rows = shell('content', 'query', '--uri', 'content://com.android.contacts/contacts', '--projection', '_id')
if '_id=' in rows:
    raise SystemExit('Address book is not empty. No contacts were added or changed.')

fixtures = [
    ('Анна Тестова', [
        ('phone_v2', {'data1': '+1 202-555-0101', 'data2': 2}),
        ('phone_v2', {'data1': '+1 202-555-0102', 'data2': 3, 'is_primary': 1, 'is_super_primary': 1}),
        ('email_v2', {'data1': 'anna@example.invalid', 'data2': 1}),
        ('email_v2', {'data1': 'anna.work@example.invalid', 'data2': 2}),
        ('postal-address_v2', {'data1': 'Тестовый город, Учебная улица, 1', 'data2': 1}),
        ('organization', {'data1': 'Учебная компания', 'data4': 'Инженер', 'data2': 1}),
        ('website', {'data1': 'https://example.invalid', 'data2': 1}),
        ('note', {'data1': 'Вымышленный контакт для лабораторной №2'}),
        ('contact_event', {'data1': '2000-03-02', 'data2': 3}),
    ]),
    ('Борис Безтелефона', [('email_v2', {'data1': 'boris@example.invalid', 'data2': 1})]),
    ('Вера Безпочты', [('phone_v2', {'data1': '+1 202-555-0103', 'data2': 2})]),
    ('Глеб Толькоимя', []),
    ('Test Contact', [('phone_v2', {'data1': '+1 202-555-0105', 'data2': 2})]),
    ('Ёлкин Тест', [('phone_v2', {'data1': '+1 202-555-0104', 'data2': 2})]),
]

def add_data(raw_id, mime, values):
    args = ['content', 'insert', '--uri', 'content://com.android.contacts/data',
            '--bind', f'raw_contact_id:i:{raw_id}', '--bind', f'mimetype:s:vnd.android.cursor.item/{mime}']
    for key, value in values.items():
        args.extend(['--bind', f'{key}:{"i" if isinstance(value, int) else "s"}:{value}'])
    shell(*args)

def raw_ids():
    rows = shell('content', 'query', '--uri', 'content://com.android.contacts/raw_contacts', '--projection', '_id')
    return set(re.findall(r'_id=(\d+)', rows))

for name, fields in fixtures:
    before = raw_ids()
    shell('content', 'insert', '--uri', 'content://com.android.contacts/raw_contacts',
          '--bind', 'account_type:n:', '--bind', 'account_name:n:')
    inserted = raw_ids() - before
    if len(inserted) != 1:
        raise RuntimeError('Could not uniquely identify the inserted raw contact.')
    raw_id = inserted.pop()
    add_data(raw_id, 'name', {'data1': name})
    for mime, values in fields:
        add_data(raw_id, mime, values)
print(f'Added {len(fixtures)} fictional contacts to {serial}.')
