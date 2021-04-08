import unittest
from . import BaseTest
from unittest import expectedFailure
from time import sleep


class PromoteCoursesTest(BaseTest, unittest.TestCase):

    def test_no_customer_success(self):
        """Get the output of promote package when there are no customers"""
        q = self.generate_query('promote_courses', ())
        res = self.execute_query(q)
        assert len(res) == 0, "There are no customers"

    def setUp(self) -> None:
        """Setup for the promote courses test"""
        # Set up the environment
        self.setup_env()
        self.customers = []

        # Call the superclass
        return super().setUp()

    def setup_env(self):
        """Set up the packages and courses"""

        # Add the staff
        self.manager_id = self._add_person('Manager', "ARRAY['Database']")
        self.admin_id = self._add_person('Admin')
        self.instructor_id = self._add_person(
            'Instructor', "ARRAY['Database']")

        # Add the room
        self.room_id = self._add_room(1, 'Test room 1', 10)

        # Add the course and sessions
        self.course_id = self._add_course('Database', 1)
        self.future_course_offering = self._add_course_offering(
            '2021-02-02', 30, [('2021-06-07', 9, self.room_id), ('2021-06-07', 11, self.room_id)], '2021-05-05', 10, self.course_id, self.admin_id)

    def add_active_customer(self, args: tuple):
        # Create customer
        
        q = self.generate_query('register_session', args)
        self.execute_query(q)

    def set_active_custs(self):
        """Set up the active customers"""
        self.customer1 = self._add_customer(
            'Johnny', 'Test', 123456789, 'test@test.com', '1234123412341234', '123', '2025-05-03')
        self.customer2 = self._add_customer(
            'Joven', 'Test', 123456780, 'test@test.com', '4321432143214324', '123', '2025-05-03')

        # Ensure that Registers have different timestamp
        q = 'LOCK TABLE Registers IN SHARE MODE;'
        self.execute_query(q) # No return value

        args1 = tuple(map(str, ('2021-02-02', self.course_id,
                               1, self.customer1, 'Credit Card')))
        args2 = tuple(map(str, ('2021-02-02', self.course_id,
                                1, self.customer2, 'Credit Card')))

        self.add_active_customer(args1)
        self.add_active_customer(args2)

        

    def add_inactive_cust(self):
        """Create inactive customers"""
        self.customer3 = self._add_customer(
            'Javier', 'Test', 123456789, 'test@test.com', '4321432143214321', '123', '2025-05-03')

    def test_all_customers_success(self):
        """Get all the customers who are inactive"""

        # Create active and inactive customers
        self.set_active_custs()
        self.add_inactive_cust()

        # Execute the query
        q = self.generate_query('promote_courses', ())
        res = self.execute_query(q)
        expected = [(f'({self.course_id},Javier,Database,{self.course_id},"Database Systems",2021-02-02,2021-05-05,30.00)',)]

    def test_all_customer_active_success(self):
        """All the customers are active and it returns nothing"""
        # Create the active customers
        self.set_active_custs()

        q = self.generate_query('promote_courses', ())
        res = self.execute_query(q)
        assert len(res) == 0, f"There is suppose to be no customers {res}"
