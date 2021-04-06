import unittest
from unittest import expectedFailure
from . import BaseTest


class ZGetAvailableCoursePackages(BaseTest, unittest.TestCase):
    def test_no_course_packages(self):
        """No course packages should result in an empty result"""
        q = self.generate_query("get_available_course_packages", ())
        res = self.execute_query(q)

        assert (
            len(res) == 0
        ), "There should be no course packages available if there are no course packages added"
        assert res == [], "There should be no course packages"

    def test_all_package_avail(self):
        """All course packages available"""
        # Add 2 course packages to the table
        args = ('Best package', '10', '2020-04-04', '2023-05-06', '200.01')
        query = self.generate_query('add_course_package', args)
        res = self.execute_query(query)
        args = ('Best package2', '10', '2020-04-04', '2023-05-06', '200.01')
        query = self.generate_query('add_course_package', args)
        res = self.execute_query(query)

        # Check if there are 2 course package
        q = self.generate_query("get_available_course_packages", ())
        res = self.execute_query(q)

        assert (
            len(res) == 2
        ), "There should be 2 course packages available"
        expected =[('(\"Best package\",10,2023-05-06,200.01)',), ('(\"Best package2\",10,2023-05-06,200.01)',)]
        assert res == expected, f'\nOutput:   {res}\nExpected: {expected}'
  
    def test_some_package_avail(self):
        """Some of the packages are not available"""
        # Add 1 course package available
        args = ('Best package', '10', '2020-04-04', '2023-05-06', '200.01')
        query = self.generate_query('add_course_package', args)
        res = self.execute_query(query)

        # Add 1 course package not available
        args = ('Best package2', '10', '2020-04-04', '2021-04-01', '200.01')
        query = self.generate_query('add_course_package', args)
        res = self.execute_query(query)
     
        # Check if there are 1 course package
        q = self.generate_query("get_available_course_packages", ())
        res = self.execute_query(q)
        
        assert len(res) == 1, "There should be 1 course packages available"
        expected =[('(\"Best package\",10,2023-05-06,200.01)',)]
        assert res == expected, f'\nOutput:   {res}\nExpected: {expected}'