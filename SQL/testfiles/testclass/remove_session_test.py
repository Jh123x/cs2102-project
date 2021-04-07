import unittest
from . import BaseTest
from unittest import expectedFailure
from psycopg2.errors import RaiseException


class ZRemoveSessionTest(BaseTest, unittest.TestCase):

    def test_invalid_arguments(self):
        """Check if remove_sessions get the correct value"""
        args = ('1', '2020-01-01', '1')
        q = self.generate_query('remove_session', args)
        self.check_fail_test(q, 'Invalid arguments is suppose to return nothing', RaiseException)

    def setup_session(self):
        """Set up the sessions to be modified"""
        # Add a manager
        self.manager_id = self._add_person('Manager', "Array['Database']")

        # Add an instructor
        self.instructor_id = self._add_person('Instructor', "Array['Database']")

        # Add an admin
        self.admin_id = self._add_person('Admin')

        # Add a course
        self.course_id = self._add_course('Database', 1)

        # Add a room
        self.room_id = self._add_room(1, 'Test room 1', 20)

        # Add a customer
        self.customer_id = self._add_customer('Test1', "test", 987654321, 'test@test.com', '1234123412341234', '123', '2025-05-31')

        # Add a course offering
        self.course_offering = self._add_course_offering('2021-01-21', 10, [('2021-06-21', 9, self.room_id), ('2021-06-21', 11, self.room_id)], '2021-05-31', 20, self.course_id, self.admin_id)

        # Check the room of the current session
        qs = 'SELECT * FROM Sessions'
        res = self.execute_query(qs)
        assert len(res) == 2, "There is suppose to be 2 sessions"

    def test_remove_session_valid(self):
        """Remove a session and see if the operation completed successfully"""
        self.setup_session()

        # Remove a session
        args = (str(self.course_id), '2021-01-21', '1')
        q = self.generate_query('remove_session', args)
        self.execute_query(q) # Returns nothing

        # Check if the number of sessions has decreased
        q = 'SELECT * FROM Sessions'
        res = self.execute_query(q)
        assert len(res) == 1, 'Sessions was not removed correctly'
        

    @expectedFailure
    def test_remove_session_with_1_student_fail(self):
        """Check if removing a session with 1 student will fail"""
        raise NotImplementedError('Test is not implemented')

