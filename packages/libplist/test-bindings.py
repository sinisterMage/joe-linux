import datetime
import plistlib
import tempfile
import unittest

import plist


class PythonBindings(unittest.TestCase):
    def test_native_values_and_automatic_formats(self):
        value = {
            '表示名': 'joe Linux 日本語',
            'enabled': True,
            'count': 42,
            'items': [1, 2, 3],
            'payload': b'zero\x00end\xff',
            'date': datetime.datetime(2026, 11, 17),
        }
        for fmt in (plist.FMT_XML, plist.FMT_BINARY):
            with self.subTest(fmt=fmt):
                encoded = plist.dumps(value, fmt=fmt)
                self.assertEqual(plistlib.loads(encoded), value)
                self.assertEqual(plist.loads(encoded).get_value(), value)
                with tempfile.NamedTemporaryFile(mode='w+b') as stream:
                    stream.write(encoded)
                    stream.seek(0)
                    self.assertEqual(plist.load(stream).get_value(), value)

    def test_dictionary_assignment_keeps_unicode_keys_and_binary_data(self):
        node = plist.from_xml(plistlib.dumps({'original': True}))
        node['新しいキー'] = 'café 日本語'
        node['payload'] = b'\x00\xffunchanged\x00'
        expected = {
            'original': True,
            '新しいキー': 'café 日本語',
            'payload': b'\x00\xffunchanged\x00',
        }
        self.assertEqual(plistlib.loads(node.to_xml().encode('utf-8')), expected)
        self.assertEqual(plistlib.loads(node.to_bin()), expected)


if __name__ == '__main__':
    unittest.main()
