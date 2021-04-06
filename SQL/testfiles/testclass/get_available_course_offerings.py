import unittest
from . import BaseTest
from unittest import expectedFailure


class ZGetAvailableCourseOfferings(BaseTest, unittest.TestCase):
    def test_no_course_offering_available(self):
        """No offering available should return empty list"""
        q = self.generate_query("get_available_course_offerings", ())
        res = self.execute_query(q)

        assert len(res) == 0, "No course offering available should return empty table"

    @expectedFailure
    def test_course_offering_over(self):
        """All course offerings are over"""
        raise NotImplementedError("Test is not implemented")

    @expectedFailure
    def test_course_offering_avail(self):
        """All course offering are available"""
        raise NotImplementedError("Test is not implemented")

    @expectedFailure
    def test_course_offering_half_avail(self):
        """Only some of the course offering are avail"""
        raise NotImplementedError("Test is not implemented")
