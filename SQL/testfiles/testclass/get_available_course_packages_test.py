import unittest
from unittest import expectedFailure
from . import BaseTest


class ZGetAvailableCoursePackages(BaseTest, unittest.TestCase):
    def test_no_course_packages(self):
        """No courses should result in an empty result"""
        q = self.generate_query("get_available_course_packages", ())
        res = self.execute_query(q)

        assert (
            len(res) == 0
        ), "There should be no courses available if there are no courses added"
        assert res == [], "There should be no courses"

    @expectedFailure
    def test_all_package_avail(self):
        """All course packages available"""
        raise NotImplementedError("This test is not implemented")

    @expectedFailure
    def test_some_package_avail(self):
        """Some of the packages are not available"""
        raise NotImplementedError("This test is not implemented")