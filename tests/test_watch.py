import unittest

from tomotv.watch import WatchTracker, merge_segments


def play(tracker, start_ms, seconds, tick_ms=250, wall_start=0.0):
    """Simulate real-time playback from start_ms for `seconds`."""
    pos, wall = start_ms, wall_start
    tracker.observe(pos, wall, True)
    for _ in range(int(seconds * 1000 / tick_ms)):
        pos += tick_ms
        wall += tick_ms
        tracker.observe(pos, wall, True)
    return pos, wall


class WatchTrackerTest(unittest.TestCase):
    def test_real_time_playback_counts(self):
        t = WatchTracker(duration_ms=100_000)
        play(t, 0, 50)
        self.assertAlmostEqual(t.fraction(), 0.5, places=2)

    def test_seeking_ahead_does_not_count(self):
        t = WatchTracker(duration_ms=100_000)
        t.observe(0, 0, True)
        t.observe(80_000, 250, True)  # jumped to 80s within a quarter second
        self.assertEqual(t.watched_ms(), 0)

    def test_small_seek_steps_do_not_count(self):
        t = WatchTracker(duration_ms=100_000)
        pos, wall = 0, 0
        t.observe(pos, wall, True)
        for _ in range(100):  # skip forward 1s every 100ms
            pos += 1000
            wall += 100
            t.observe(pos, wall, True)
        self.assertEqual(t.watched_ms(), 0)

    def test_rewatching_the_same_part_counts_once(self):
        t = WatchTracker(duration_ms=100_000)
        play(t, 0, 30)
        t.reset_anchor()
        play(t, 0, 30, wall_start=100_000)
        self.assertAlmostEqual(t.fraction(), 0.3, places=2)

    def test_pause_does_not_count(self):
        t = WatchTracker(duration_ms=100_000)
        play(t, 0, 10)
        t.observe(10_000, 10_000, False)
        t.observe(10_000, 60_000, False)
        self.assertAlmostEqual(t.fraction(), 0.1, places=2)

    def test_resume_after_pause_continues(self):
        t = WatchTracker(duration_ms=100_000)
        pos, wall = play(t, 0, 10)
        t.observe(pos, wall, False)
        play(t, pos, 10, wall_start=wall + 30_000)
        self.assertAlmostEqual(t.fraction(), 0.2, places=2)

    def test_skip_opening_still_reaches_threshold(self):
        t = WatchTracker(duration_ms=1_440_000)  # 24 min episode
        play(t, 0, 60)                               # cold open
        t.reset_anchor()
        play(t, 150_000, 1_200, wall_start=10**7)    # skipped the 90s opening
        self.assertGreaterEqual(t.fraction(), 0.70)

    def test_merge_segments(self):
        self.assertEqual(merge_segments([[0, 10], [5, 20], [100, 200], [20, 30]]), [[0, 30], [100, 200]])


if __name__ == "__main__":
    unittest.main()
