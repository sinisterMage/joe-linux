"""Real GLib-loop file jobs must complete when their producer never yields."""
import asyncio
import hashlib
import os
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, os.getcwd())
from src._async import event_loop
from src.utils.asynctask import EartagAsyncMultitasker


class QueuedFileLoading(unittest.TestCase):
    def test_immediate_producer_and_reused_loader_complete(self):
        async def consume():
            completed = asyncio.Event()
            actual = {}

            async def read_file(path):
                actual[path.name] = hashlib.sha256(path.read_bytes()).hexdigest()

            tasker = EartagAsyncMultitasker(read_file, workers=3)
            tasker.connect("task-done", lambda *_: completed.set())
            with tempfile.TemporaryDirectory() as directory:
                for batch in ((b"first file\x00\xff",), (b"second", b"third", b"fourth")):
                    paths = []
                    expected = {}
                    for index, payload in enumerate(batch):
                        path = Path(directory, f"file-{index}")
                        path.write_bytes(payload)
                        paths.append(path)
                        expected[path.name] = hashlib.sha256(payload).hexdigest()
                    actual.clear()
                    completed.clear()
                    tasker.spawn_workers()
                    # An unbounded Queue.put need not suspend. This must finish
                    # filling the batch before the scheduled workers run.
                    await tasker.queue_put_multiple_async(paths, mark_as_done=True)
                    await asyncio.wait_for(completed.wait(), timeout=5)
                    self.assertEqual(actual, expected)
                    self.assertFalse(tasker.props.is_running)

        event_loop.run_until_complete(consume())


if __name__ == "__main__":
    unittest.main()
