import unittest
from . import BaseTest
from unittest import expectedFailure


class ZGetAvailableCourseSessionsTest(BaseTest, unittest.TestCase):
    def test_no_sessions_avail(self):
        """Return nothing when there are no sessions"""
        # Using information that is not found
        args = ("2020-04-21", "1")

        # Execute the function
        q = self.generate_query("get_available_course_sessions", args)
        res = self.execute_query(q)

        # Check that it is empty
        assert res == [], f"There are no sessions {res}"