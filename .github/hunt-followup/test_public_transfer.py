"""Focused regression for the observed public-download timeout and byte guard."""
import hashlib
import importlib.util
import io
from pathlib import Path
import tempfile
import unittest
import urllib.error
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('quality2_publisher', Path(__file__).with_name('publish.py'))
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)


class PublicTransfer(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name) / 'index.pck'
        self.data = b'new!'
        self.want = {'size': len(self.data), 'sha256': hashlib.sha256(self.data).hexdigest()}

    def test_transient_timeout_and_503_recover_with_exact_bytes(self):
        for error in (TimeoutError('simulated header timeout'),
                      urllib.error.HTTPError('https://example.invalid/', 503, 'temporary', {}, None)):
            with self.subTest(error=type(error).__name__):
                with patch.object(publisher.urllib.request, 'urlopen', side_effect=[error, io.BytesIO(self.data)]) as request, \
                        patch.object(publisher.time, 'sleep'):
                    publisher.fetch('index.pck', self.path, self.want)
                self.assertEqual(request.call_count, 2)
                self.assertEqual(self.path.read_bytes(), self.data)
                self.assertFalse(self.path.with_name('index.pck.download').exists())

    def test_wrong_hash_stops_without_retry_or_replacing_previous_file(self):
        self.path.write_bytes(b'old!')
        with patch.object(publisher.urllib.request, 'urlopen', return_value=io.BytesIO(b'oops')) as request:
            with self.assertRaisesRegex(RuntimeError, 'Public content changed'):
                publisher.fetch('index.pck', self.path, self.want)
        self.assertEqual(request.call_count, 1)
        self.assertEqual(self.path.read_bytes(), b'old!')
        self.assertFalse(self.path.with_name('index.pck.download').exists())

    def test_repeated_timeout_is_bounded_and_preserves_previous_file(self):
        self.path.write_bytes(b'old!')
        with patch.object(publisher.urllib.request, 'urlopen', side_effect=TimeoutError('simulated')) as request, \
                patch.object(publisher.time, 'sleep'):
            with self.assertRaisesRegex(RuntimeError, 'after three attempts'):
                publisher.fetch('index.pck', self.path, self.want)
        self.assertEqual(request.call_count, 3)
        self.assertEqual(self.path.read_bytes(), b'old!')
        self.assertFalse(self.path.with_name('index.pck.download').exists())

    def test_access_error_is_not_retried(self):
        error = urllib.error.HTTPError('https://example.invalid/', 403, 'forbidden', {}, None)
        with patch.object(publisher.urllib.request, 'urlopen', side_effect=error) as request:
            with self.assertRaises(urllib.error.HTTPError):
                publisher.fetch('index.pck', self.path, self.want)
        self.assertEqual(request.call_count, 1)
        self.assertFalse(self.path.exists())


if __name__ == '__main__':
    unittest.main()
