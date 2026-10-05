import os
import tempfile
import unittest

from tomotv.schedule import DAY, WEEK
from tomotv.station import Station
from tomotv.store import Store


class FakeClock:
    def __init__(self, t=1_000_000.0):
        self.t = t

    def __call__(self):
        return self.t


class StationTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.clock = FakeClock()
        self.station = Station(Store(os.path.join(self.dir.name, "state.json")), self.clock)
        eps = [{"file": f"ep{i}.mkv", "name": f"Ep {i}", "number": str(i)} for i in range(1, 4)]
        self.ch = self.station.add_channel(self.dir.name, "Show", eps)

    def tearDown(self):
        self.dir.cleanup()

    def watch(self, session, seconds, start=0):
        """Play in real time; returns the last result plus whether it completed during this run."""
        pos, wall = start, 0.0
        session.seeked()
        result = session.observe(pos, 100_000, True, wall)
        newly = False
        for _ in range(seconds * 4):
            pos += 250
            wall += 250
            result = session.observe(pos, 100_000, True, wall)
            newly = newly or result["newlyCompleted"]
        return {**result, "newlyCompleted": newly}

    def test_full_flow(self):
        st = self.station
        self.assertIsNone(st.start_session(self.ch["id"], 1), "episode 2 has not aired")
        s = st.start_session(self.ch["id"], 0)
        r = self.watch(s, 60)
        self.assertFalse(r["completed"], "60% is not enough")
        r = self.watch(s, 15, start=60_000)
        self.assertTrue(r["completed"])
        self.assertTrue(r["newlyCompleted"])
        s.close()
        self.assertIsNone(st.start_session(self.ch["id"], 1), "still airs next week")

        self.clock.t += WEEK
        self.assertIsNotNone(st.start_session(self.ch["id"], 1))
        view = st.view(self.ch)
        self.assertTrue(view["canWatch"])
        self.assertEqual(view["nextIndex"], 1)

    def test_persistence(self):
        s = self.station.start_session(self.ch["id"], 0)
        self.watch(s, 80)
        s.close(80_000)
        again = Station(Store(os.path.join(self.dir.name, "state.json")), self.clock)
        ch = again.get(self.ch["id"])
        self.assertTrue(ch["episodes"][0]["done"])
        self.assertEqual(again.data["stats"]["completed"], 1)

    def test_clock_going_back_does_not_relock(self):
        self.clock.t += 2 * WEEK
        self.assertEqual(self.station.view(self.ch)["aired"], 3)
        self.clock.t -= 2 * WEEK
        self.assertEqual(self.station.view(self.ch)["aired"], 3)

    def test_restart(self):
        s = self.station.start_session(self.ch["id"], 0)
        self.watch(s, 80)
        self.clock.t += DAY
        self.station.restart_channel(self.ch["id"])
        view = self.station.view(self.ch)
        self.assertEqual(view["watched"], 0)
        self.assertEqual(view["aired"], 1)

    def test_resume_position(self):
        s = self.station.start_session(self.ch["id"], 0)
        self.watch(s, 20)
        s.close(20_000)
        s2 = self.station.start_session(self.ch["id"], 0)
        self.assertEqual(s2.resume_position(), 20_000)


if __name__ == "__main__":
    unittest.main()
