import unittest

from tomotv import schedule
from tomotv.schedule import DAY, NEXT, QUEUED, UPCOMING, WATCHED, WEEK

P = 1_000_000.0  # premiere


class ScheduleTest(unittest.TestCase):
    def test_first_episode_airs_at_premiere(self):
        self.assertEqual(schedule.aired_count(P, WEEK, 12, P), 1)
        self.assertEqual(schedule.aired_count(P, WEEK, 12, P - 1), 0)

    def test_one_episode_per_week(self):
        self.assertEqual(schedule.aired_count(P, WEEK, 12, P + WEEK - 1), 1)
        self.assertEqual(schedule.aired_count(P, WEEK, 12, P + WEEK), 2)
        self.assertEqual(schedule.aired_count(P, WEEK, 12, P + 20 * WEEK), 12)

    def test_states_fresh_channel(self):
        states = schedule.episode_states([False] * 4, P, WEEK, P + DAY)
        self.assertEqual(states, [NEXT, UPCOMING, UPCOMING, UPCOMING])

    def test_episodes_stack_but_stay_in_order(self):
        # Two weeks later without watching: three episodes aired, only the first is watchable.
        now = P + 2 * WEEK + DAY
        states = schedule.episode_states([False] * 4, P, WEEK, now)
        self.assertEqual(states, [NEXT, QUEUED, QUEUED, UPCOMING])
        self.assertTrue(schedule.can_play([False] * 4, P, WEEK, now, 0))
        self.assertFalse(schedule.can_play([False] * 4, P, WEEK, now, 1))

    def test_watching_unlocks_next_aired_episode_immediately(self):
        now = P + 2 * WEEK + DAY
        states = schedule.episode_states([True, False, False, False], P, WEEK, now)
        self.assertEqual(states, [WATCHED, NEXT, QUEUED, UPCOMING])

    def test_watched_but_next_not_aired(self):
        now = P + DAY
        s = schedule.summarize([True, False, False], P, WEEK, now)
        self.assertFalse(s.can_watch)
        self.assertEqual(s.next_index, 1)
        self.assertEqual(s.next_air, P + WEEK)
        self.assertEqual(s.backlog, 0)

    def test_summary_backlog_and_finish(self):
        s = schedule.summarize([True, False, False], P, WEEK, P + 5 * WEEK)
        self.assertTrue(s.can_watch)
        self.assertEqual(s.backlog, 2)
        self.assertIsNone(s.next_air)
        done = schedule.summarize([True, True, True], P, WEEK, P + 5 * WEEK)
        self.assertTrue(done.finished)

    def test_reruns_allowed(self):
        self.assertTrue(schedule.can_play([True, False], P, WEEK, P + DAY, 0))
        self.assertFalse(schedule.can_play([True, False], P, WEEK, P + DAY, 1))
        self.assertFalse(schedule.can_play([True, False], P, WEEK, P + DAY, 5))


if __name__ == "__main__":
    unittest.main()
