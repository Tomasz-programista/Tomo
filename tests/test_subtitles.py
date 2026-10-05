import unittest

from tomotv import subtitles
from tomotv.subtitles import CueTrack, format_text

ASS = """[Script Info]
ScriptType: v4.00+

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,48,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,2,0,2,10,10,10,1
Style: Top,Arial,36,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,2,0,8,10,10,10,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:04.00,Default,,0,0,0,,{\\i1}Hello,{\\i0} world, with commas!
Dialogue: 0,0:00:02.50,0:00:03.00,Top,,0,0,0,,A sign
Comment: 0,0:00:01.00,0:00:04.00,Default,,0,0,0,,not shown
Dialogue: 0,0:00:05.00,0:00:06.00,Default,,0,0,0,,{\\p1}m 0 0 l 100 0 100 100{\\p0}
Dialogue: 0,0:00:07.00,0:00:08.00,Default,,0,0,0,,Line one\\NLine two
"""

SRT = """1
00:00:01,000 --> 00:00:02,500
<i>Italic</i> & <b>bold</b>

2
00:01:00,000 --> 00:01:01,000
{\\an8}Top line
"""


class FormatTest(unittest.TestCase):
    def test_ass_tags(self):
        self.assertEqual(format_text("{\\i1}Hi{\\i0} there")[0], "<i>Hi</i> there")
        self.assertEqual(format_text("a\\Nb")[0], "a<br>b")
        self.assertEqual(format_text("{\\blur3\\bord2}x")[0], "x")
        self.assertEqual(format_text("{\\p1}m 0 0 l 1 1")[0], "")
        self.assertTrue(format_text("{\\an8}sign")[1])
        self.assertTrue(format_text("{\\pos(10,10)}sign")[2])

    def test_html_escaping_and_unclosed(self):
        self.assertEqual(format_text("<i>1 < 2 & 3")[0], "<i>1 &lt; 2 &amp; 3</i>")


class ParseTest(unittest.TestCase):
    def test_ass(self):
        cues = subtitles.parse_ass(ASS)
        self.assertEqual(len(cues), 3)
        self.assertEqual(cues[0].text, "<i>Hello,</i> world, with commas!")
        self.assertTrue(cues[1].top)
        track = CueTrack(cues)
        self.assertEqual(track.text_at(2600), ("A sign", "<i>Hello,</i> world, with commas!"))
        self.assertEqual(track.text_at(4500), ("", ""))
        self.assertEqual(track.text_at(7500)[1], "Line one<br>Line two")

    def test_srt(self):
        cues = subtitles.parse_srt(SRT)
        self.assertEqual(cues[0].start, 1000)
        self.assertEqual(cues[0].text, "<i>Italic</i> &amp; <b>bold</b>")
        self.assertTrue(cues[1].top)

    def test_vtt(self):
        cues = subtitles.parse_vtt("WEBVTT\n\n00:01.000 --> 00:02.000 line:0\n<v Bob>Hi</v>\n")
        self.assertEqual((cues[0].start, cues[0].text, cues[0].top), (1000, "Hi", True))

    def test_decode_shift_jis(self):
        self.assertEqual(subtitles.decode_bytes("こんにちは".encode("cp932")), "こんにちは")


if __name__ == "__main__":
    unittest.main()
