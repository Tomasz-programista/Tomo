import os
import tempfile
import unittest

from tomotv import library
from tomotv.library import parse_episode


class ParseEpisodeTest(unittest.TestCase):
    def num(self, name):
        p = parse_episode(name)
        return p.number if p else None

    def test_common_release_names(self):
        self.assertEqual(self.num("[SubsPlease] Sousou no Frieren - 01 (1080p) [ABCD1234]"), 1)
        self.assertEqual(self.num("[Erai-raws] Show Name - 12v2 [1080p][Multiple Subtitle]"), 12)
        self.assertEqual(self.num("Show.Name.S01E05.1080p.WEB-DL.x264"), 5)
        self.assertEqual(self.num("Show Name S02E10"), 10)
        self.assertEqual(self.num("[philosophy-raws][Show][07][BDRIP][Hi10P FLAC][1920X1080]"), 7)
        self.assertEqual(self.num("Show Name Episode 3"), 3)
        self.assertEqual(self.num("Show Name EP09 720p"), 9)
        self.assertEqual(self.num("ショー 第11話「タイトル」"), 11)
        self.assertEqual(self.num("Show_Name_08_[720p]"), 8)
        self.assertEqual(self.num("Show Name - 13.5 - Recap"), 13.5)
        self.assertEqual(self.num("Cowboy Bebop 2001 - 04"), 4)

    def test_season_is_kept(self):
        p = parse_episode("Show S02E03")
        self.assertEqual((p.season, p.number), (2, 3))

    def test_resolution_is_not_an_episode(self):
        self.assertEqual(self.num("Show Name 1080p"), None)

    def test_extras(self):
        self.assertTrue(library.is_extra("[Group] Show - NCOP1 (1080p)"))
        self.assertTrue(library.is_extra("[Group] Show - NCED (1080p)"))
        self.assertTrue(library.is_extra("Show - PV 2"))
        self.assertTrue(library.is_extra("Show Creditless Opening"))
        self.assertFalse(library.is_extra("[Group] Show - 01 (1080p)"))
        self.assertFalse(library.is_extra("Never Ending Story - 01"))

    def test_clean_title(self):
        self.assertEqual(library.guess_title("/x/Mahou Shoujo Test (2004) [BD 1080p]"), "Mahou Shoujo Test")
        self.assertEqual(library.guess_title("/x/[Group] Some_Show_Name"), "Some Show Name")
        self.assertEqual(library.guess_title("/x/Show.Name.S01.1080p.BluRay.x264"), "Show Name S01")


class ScanFolderTest(unittest.TestCase):
    def make(self, folder, names):
        for n in names:
            path = os.path.join(folder, n)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            open(path, "wb").close()

    def test_orders_and_flags_extras(self):
        with tempfile.TemporaryDirectory() as d:
            self.make(d, [
                "[G] Show - 10 (1080p).mkv",
                "[G] Show - 02 (1080p).mkv",
                "[G] Show - 01 (1080p).mkv",
                "[G] Show - NCOP1 (1080p).mkv",
                "[G] Show - 02v2 (1080p).mkv",
                "notes.txt",
                "cover.jpg",
            ])
            r = library.scan_folder(d)
            included = [i.file for i in r.items if i.include]
            self.assertEqual(included, ["[G] Show - 01 (1080p).mkv", "[G] Show - 02v2 (1080p).mkv", "[G] Show - 10 (1080p).mkv"])
            kinds = {i.file: i.kind for i in r.items}
            self.assertEqual(kinds["[G] Show - NCOP1 (1080p).mkv"], "extra")
            self.assertEqual(kinds["[G] Show - 02 (1080p).mkv"], "duplicate")
            self.assertTrue(r.cover.endswith("cover.jpg"))

    def test_season_subfolder(self):
        with tempfile.TemporaryDirectory() as d:
            self.make(d, ["Season 1/Ep 2.mp4", "Season 1/Ep 1.mp4"])
            r = library.scan_folder(d)
            self.assertEqual([i.file for i in r.items], [os.path.join("Season 1", "Ep 1.mp4"), os.path.join("Season 1", "Ep 2.mp4")])

    def test_empty_folder(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertTrue(library.scan_folder(d).warning)

    def test_external_subtitles(self):
        with tempfile.TemporaryDirectory() as d:
            self.make(d, [
                "Show - 01.mkv", "Show - 02.mkv",
                "Show - 01.en.srt", "Show - 02.en.srt",
                "Subs/[Other] Show - 01 [eng].ass", "Subs/[Other] Show - 02 [eng].ass",
                "Subs/Show - 01/2_English.srt",
            ])
            groups = library.match_external_subtitles(d, ["Show - 01.mkv", "Show - 02.mkv"])
            self.assertIn("….en.srt", groups)
            self.assertEqual(len(groups["….en.srt"]), 2)
            self.assertIn("Subs/[Other] Show - # [eng].ass", groups)
            self.assertIn("Subs/…/2_English.srt", groups)
            self.assertEqual(library.describe_sub_label("….en.srt"), "en (SRT)")


if __name__ == "__main__":
    unittest.main()
