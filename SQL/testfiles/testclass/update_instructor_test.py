import unittest
from . import BaseTest
from unittest import expectedFailure
from psycopg2.errors import RaiseException


class ZUpdateInstructorTest(BaseTest, unittest.TestCase):

    def test_invalid_args(self):
        """Call the function using invalid arguments"""
        args = ('2020-04-01', '1', '1', '1')
        q = self.generate_query('update_instructor', args)
        self.check_fail_test(q, 'Invalid arguments should throw an error', RaiseException)


    def setup_session(self):
        """Set up the sessions to be modified"""
        # Add a manager
        self.manager_id = self._add_person('Manager', "Array['Database']")

        # Add an instructor
        self.instructor_id = self._add_person('Instructor', "Array['Database']")
        self.instructor_id1 = self._add_person('Instructor', "Array['Database']")

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

    def test_check_update_instructor(self):
        """Check if the update instructor is working"""
        # Setup the sessions
        self.setup_session()

        # Check the instructor for the session beforehand
        qs = 'SELECT * FROM Sessions'
        res = self.execute_query(qs) # Both should add self.instructor to the db
        r = tuple(map(lambda x: x[-1], res))
        assert r == (self.instructor_id, self.instructor_id), f"The instructor was assigned unexpectedly {res} {r}"

        # Change the first session to the 2nd buy
        args = ('2021-01-21', str(self.course_id), '1', str(self.instructor_id1))
        q = self.generate_query('update_instructor', args)
        self.execute_query(q) # Does not return

        # Check the instructor for the session beforehand
        qs = 'SELECT * FROM Sessions'
        res = self.execute_query(qs) # Both should add self.instructor to the db
        assert set(map(lambda x: x[-1], res)) == set((self.instructor_id1, self.instructor_id)), f"The was not changed correctly {res}"



