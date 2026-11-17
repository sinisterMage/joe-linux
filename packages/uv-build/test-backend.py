import contextlib
from decimal import Decimal
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile

import uv_build


class PreparedMetadataPackages(unittest.TestCase):
    def check_package(self, editable):
        with tempfile.TemporaryDirectory(prefix='uv-build-consumer-') as directory:
            root = Path(directory)
            project = root / 'project'
            module = project / 'src/tier2_backend_fixture'
            module.mkdir(parents=True)
            (project / 'pyproject.toml').write_text('''[build-system]
requires = ["uv_build==0.13.8"]
build-backend = "uv_build"

[project]
name = "tier2-backend-fixture"
version = "1.0.0"
requires-python = ">=3.15"

[tool.uv.build-backend]
module-name = "tier2_backend_fixture"
module-root = "src"
''')
            (module / '__init__.py').write_text('''import csv
from decimal import Decimal
from importlib.resources import files
import io

def total():
    rows = csv.DictReader(io.StringIO(files(__package__).joinpath("prices.csv").read_text()))
    return sum((Decimal(row["count"]) * Decimal(row["price"]) for row in rows), Decimal(0))
''')
            prices = module / 'prices.csv'
            prices.write_text('name,count,price\none,3,1.25\ntwo,2,4.50\n')
            metadata = root / 'metadata'
            wheels = root / 'wheels'
            metadata.mkdir()
            wheels.mkdir()
            prepare = (uv_build.prepare_metadata_for_build_editable if editable
                       else uv_build.prepare_metadata_for_build_wheel)
            build = uv_build.build_editable if editable else uv_build.build_wheel
            with contextlib.chdir(project):
                info = prepare(str(metadata))
                wheel = build(str(wheels), metadata_directory=str(metadata / info))
            installed = root / 'installed'
            installed.mkdir()
            with zipfile.ZipFile(wheels / wheel) as archive:
                archive.extractall(installed)
            # A normal wheel retains its packaged resource; an editable wheel
            # must observe a later edit to the source resource instead.
            prices.write_text('name,count,price\nchanged,5,2.00\n')
            code = ('import site,sys; site.addsitedir(sys.argv[1]); '
                    'import tier2_backend_fixture; print(tier2_backend_fixture.total())')
            result = subprocess.run([sys.executable, '-I', '-c', code, str(installed)],
                                    cwd=root, check=True, text=True,
                                    stdout=subprocess.PIPE)
            expected = Decimal('10.00') if editable else Decimal('12.75')
            self.assertEqual(Decimal(result.stdout.strip()), expected)

    def test_prepared_wheel_installs_code_and_resource(self):
        self.check_package(editable=False)

    def test_prepared_editable_observes_live_resource(self):
        self.check_package(editable=True)


if __name__ == '__main__':
    unittest.main()
