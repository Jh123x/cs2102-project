import unittest
from . import BaseTest
from psycopg2.errors import UniqueViolation


class GAddCoursePackageTest(BaseTest, unittest.TestCase):

    def test_add_different_packages_success(self):
        """Adding 2 different packages should succeed"""
        # Add the course package 1 time
        args = ('Best package', '10', '2020-04-04', '2023-05-06', '200.01')
        query = self.generate_query('add_course_package', args)
        res = self.execute_query(query)

        assert res[0][0] == 1, f"Wrong Id {res}"

        # Add the course package 1 more time
        args = ('Best package2', '10', '2020-04-04', '2023-05-06', '200.01')
        query = self.generate_query('add_course_package', args)
        res = self.execute_query(query)

        assert res[0][0] == 2, f"Wrong Id {res}"

    def test_add_duplicate_package_success(self):
        """Adding a duplicated package should succeed"""
        # Add the course package 1 time
        args = ('Best package', '10', '2020-04-04', '2023-05-06', '200.01')
        query = self.generate_query('add_course_package', args)
        res = self.execute_query(query)

        assert res[0][0] == 3, f"Wrong id {res}"

        # Add a package into the data
        args = ('Best package', '10', '2020-04-04', '2023-05-06', '200.01')
        query = self.generate_query('add_course_package', args)
        res = self.execute_query(query)

        assert res[0][0] == 4, f"Wrong id {res}"

    def test_add_package_success(self):
        """Adding a course package should succeed"""

        # Add a package into the data
        args = ('Best package', '10', '2020-04-04', '2023-05-06', '200.01')
        query = self.generate_query('add_course_package', args)
        res = self.execute_query(query)

        # Check if the returned id is correct
        assert res[0][0] == 5, f"Wrong id {res}"
