import unittest
from . import BaseTest
from unittest import expectedFailure


class ZGetMyCoursePackage(BaseTest, unittest.TestCase):
    def test_customer_does_not_exists(self):
        """Should return empty if the customer does not exist"""
        q = self.generate_query("get_my_course_package", ("1",))
        res = self.execute_query(q)

        assert res == [
            ({},)
        ], f"The function should return an empty json when the customer is not found {res}"

    @expectedFailure
    def test_customer_with_no_packages(self):
        """Should return empty when the customer has no packages"""
        raise NotImplementedError("Test is not implemented")

    @expectedFailure
    def test_customer_with_1_package(self):
        """Return the 1 active package that the customer has"""
        raise NotImplementedError("Test is not implemented")

    @expectedFailure
    def test_customer_with_many_packages(self):
        """Return the many packages that the customer has"""
        raise NotImplementedError("Test is not implemented")
