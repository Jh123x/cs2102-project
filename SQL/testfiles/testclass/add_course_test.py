import unittest
from psycopg2.errors import UniqueViolation
from .basetest import BaseTest


class CAddCourseTest(BaseTest, unittest.TestCase):

    def setUp(self) -> None:
        # Add a manager who manages the area
        self._add_person('Manager', "ARRAY['Database']")
        return super().setUp()

    def test_add_course(self):
        """Check if the add_course if working correctly"""
        args = ("Database Systems", "A db about databases", "Database", '4')
        q = self.generate_query('add_course', args)

        val = self.execute_query(q)
        assert len(val) == 1, f"Invalid return value {val}"

    def test_add_course_with_exists(self):
        """Test a course which already exists"""
        args = ("Database Systems", "A db about databases", "Database", '4')
        q = self.generate_query('add_course', args)

        # Add it the first time
        val = self.execute_query(q)
        assert len(val) == 1, "The initial adding is incorrect"

        # Add it again
        val = self.check_fail_test(q, "Should have a unique violation", (UniqueViolation,))

