import unittest
from . import BaseTest
from unittest import expectedFailure
from psycopg2.errors import RaiseException


class ZUpdateCourseSessionTest(BaseTest, unittest.TestCase):

    def test_update_invalid_all(self):
        """Test on invalid customer id"""
        args = ('1', '1', '2020-05-12', '2')
        q = self.generate_query('update_course_session', args)
        self.check_fail_test(q, "Invalid Session", RaiseException)

    def setup_sessions(self):
        """Set up the people needed to test the data"""
        # Add a manager
        self.manager_id = self._add_person('Manager', "Array['Database']")

        # Add an instructor
        self.instructor_id = self._add_person('Instructor', "Array['Database']")

        # Add an admin
        self.admin_id = self._add_person('Admin')

        # Add a course
        self.course_id = self._add_course('Database', 1)

        # Add a room
        self.room_id = 1
        self._add_room(1, 'Test room', 20)

        # Add a customer
        self.customer_id = self._add_customer('Test1', "test", 987654321, 'test@test.com', '1234123412341234', '123', '2025-05-31')

        # Add a course offering
        self.course_offering = self._add_course_offering('2021-01-21', 10, [('2021-06-21', 9, self.room_id), ('2021-06-21', 11, self.room_id)], '2021-05-31', 20, self.course_id, self.admin_id)

        # Add a package
        self.package_id = self._add_course_package('Best package', 10, '2020-06-20', '2025-06-20', 10)

        # Customer buys a package
        args = (str(self.customer_id), str(self.package_id))
        q = self.generate_query('buy_course_package', args)
        self.execute_query(q)

        # Register for a package
        args = ('2021-01-21', str(self.course_id), '1', str(self.customer_id), 'Credit Card')
        q = self.generate_query('register_session', args)
        self.execute_query(q)

    def test_valid_update_success(self):
        """Check if the update is successful"""

        # Setup the sessions
        self.setup_sessions()

        # Check the registers table before
        q = 'SELECT * FROM Registers'
        initial_res = self.execute_query(q)
        assert len(initial_res) == 1, f"Customer was not successful in being added to the table {initial_res}"

        # Change from the first session to the second one
        args = (str(self.customer_id), str(self.course_id), '2021-01-21', '2')
        q = self.generate_query('update_course_session', args)
        self.execute_query(q) # Returns nothing

        # Check the registers table after
        final_res = self.execute_query(q)
        assert len(final_res) == 1, f"The update for the session was not successful"
        assert final_res != initial_res, f"The final and initial should not be the same {final_res}"


