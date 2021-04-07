import unittest
from . import BaseTest
from unittest import expectedFailure
from psycopg2.errors import RaiseException


class ZUpdateRoomTest(BaseTest, unittest.TestCase):

    def test_invalid_args(self):
        """Test invalid arguments"""
        args = ('2020-01-04', '1', '1', '1')
        q = self.generate_query('update_room', args)
        self.check_fail_test(q, "Invalid arguments should not execute the function", RaiseException)

    def setup_session(self):
        """Set up the sessions to be modified"""
        # Add a manager
        self.manager_id = self._add_person('Manager', "Array['Database']")
        self.manager_id = self._add_person('Manager', "Array['Network']")

        # Add an instructor
        self.instructor_id = self._add_person('Instructor', "Array['Database']")
        self.instructor_id = self._add_person('Instructor', "Array['Network']")

        # Add an admin
        self.admin_id = self._add_person('Admin')

        # Add a course
        self.course_id = self._add_course('Database', 1)
        self.course_id1 = self._add_course('Network', 1, 'Networks')

        # Add a room
        self.room_id = self._add_room(1, 'Test room 1', 20)
        self.room_id2 = self._add_room(2, 'Test room 2', 20)

        # Add a customer
        self.customer_id = self._add_customer('Test1', "test", 987654321, 'test@test.com', '1234123412341234', '123', '2025-05-31')

        # Add a course offering
        self.course_offering = self._add_course_offering('2021-01-21', 10, [('2021-06-21', 9, self.room_id), ('2021-06-21', 11, self.room_id)], '2021-05-31', 20, self.course_id, self.admin_id)

        # Check the room of the current session
        qs = 'SELECT * FROM Sessions'
        res = self.execute_query(qs)
        assert len(res) == 2, "There is suppose to be 2 sessions"
        assert set(map(lambda x: x[-2], res)) == set((self.room_id,)), f"Room is not assigned correctly {res}"

    def test_setup_room_success(self):
        """Test if the setup room routine works"""
        self.setup_session()

        # Update the room number
        args = ('2021-01-21', str(self.course_id), '1', str(self.room_id2))
        q = self.generate_query('update_room', args)
        self.execute_query(q) # Returns nothing

        # Check if the room number is updated
        qs = 'SELECT * FROM Sessions'
        res = self.execute_query(qs)
        assert set(map(lambda x: x[-2], res)) == set((self.room_id,self.room_id2)), f"Room is not updated correctly {res}"

    def test_setup_room_in_use_fail(self):
        """Test if adding another room in use at that time fails"""
        # Setup the room
        self.setup_session()

        # Add a course offering
        self.course_offering = self._add_course_offering('2021-02-21', 10, [('2021-06-21', 9, self.room_id2)], '2021-06-01', 20, self.course_id1, self.admin_id)

        # Update the room number to another room that is used during the timeslot
        args = ('2021-01-21', str(self.course_id), '1', str(self.room_id2))
        q = self.generate_query('update_room', args)
        self.check_fail_test(q, 'The room is also in use', RaiseException)
