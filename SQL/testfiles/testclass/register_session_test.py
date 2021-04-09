import unittest
from . import BaseTest
from psycopg2.errors import RaiseException


class ZRegisterSessionTest(BaseTest, unittest.TestCase):
    def test_invalid_resgistration_input(self):
        """Invalid registration input"""
        args = ("2020-04-21", "1", "1", "1", "Credit Card")
        q = self.generate_query("register_session", args)
        self.check_fail_test(
            q, "Invalid input should raise an exception", RaiseException)

    def test_invalid_redeem_input(self):
        """Invalid registration input"""
        args = ("2020-04-21", "1", "1", "1", "Redemption")
        q = self.generate_query("register_session", args)
        self.check_fail_test(
            q, "Invalid input should raise an exception", RaiseException)

    def test_invalid_payment_type(self):
        """Invalid payment method"""
        args = ("2020-04-21", "1", "1", "1", "Invalid Payment Method")
        q = self.generate_query("register_session", args)
        self.check_fail_test(
            q, "Invalid payment method should not pass the test case", RaiseException
        )

    def test_expired_credit_card(self):
        """Test if the customer can register using an expired credit card"""

        # Set up the course offering
        self.setup_course_offering()

        # Disable the credit card trigger temporarily
        q = 'SET session_replication_role = replica;'
        self.execute_query(q)

        # Insert a customer, credit card and owns to the table (Simulate someone with outdated card)
        cust_id2 = self._add_customer(
            'John', 'addr', 987625423, 'test@test.com', '1234128642341234', '123', '2020-05-21')

        # Enable the trigger again
        q = 'SET session_replication_role = DEFAULT;'
        self.execute_query(q)

        # This operation should fail as the credit card is expired
        args = ('2021-01-21', str(self.course_id),
                "1", str(cust_id2), "Credit Card")
        q = self.generate_query("register_session", args)
        self.check_fail_test(
            q, "Invalid credit card should not pass the test case", RaiseException
        )

    def setup_course_offering(self):
        """Set up the people needed to test the data"""
        # Add a manager
        self.manager_id = self._add_person('Manager', "Array['Database']")

        # Add an instructor
        self.instructor_id = self._add_person(
            'Instructor', "Array['Database']")

        # Add an admin
        self.admin_id = self._add_person('Admin')

        # Add a course
        self.course_id = self._add_course('Database', 2)

        # Add a room
        self.room_id = self._add_room(1, 'Test room', 20)

        # Add a customer
        self.customer_id = self._add_customer(
            'Test1', "test", 987654321, 'test@test.com', '1234123412341234', '123', '2025-05-31')

        # Add a course offering
        self.course_offering = self._add_course_offering(
            '2021-01-21', 10, [('2021-06-21', 9, 1)], '2021-05-31', 20, self.course_id, self.admin_id)

        # Add a package
        self.package_id = self._add_course_package(
            'Best package', 10, '2020-06-20', '2025-06-20', 10)

        # Customer buys a package
        args = (str(self.customer_id), str(self.package_id))
        q = self.generate_query('buy_course_package', args)
        self.execute_query(q)

    def test_valid_registration_credit_card(self):
        """Test if a valid registration can go through"""

        # Set up the course offering
        self.setup_course_offering()

        # Get the number of redemptions before the execution
        get_redeem_left_q = f'SELECT buy_num_remaining_redemptions FROM Buys WHERE customer_id = {self.customer_id}'
        before_redemptions = self.execute_query(get_redeem_left_q)[0][0]

        # Add the credit card
        args = ('2021-01-21', str(self.course_id), '1',
                str(self.customer_id), 'Credit Card')
        q = self.generate_query('register_session', args)
        self.execute_query(q)

        # Nothing should be added to redeems
        q = 'SELECT * FROM Redeems'
        res = self.execute_query(q)
        assert res == [], f"Wrong Entries in redeems {res}"

        # The registration should be added
        q = 'SELECT * FROM Registers'
        res = self.execute_query(q)
        assert len(res) > 0, f"Wrong entries in registers {res}"

        after_redemptions = self.execute_query(get_redeem_left_q)[0][0]
        assert before_redemptions == after_redemptions, "The number of redemptions should not change"

    def test_valid_registration_redeems(self):
        """Test if a valid registration can go through"""

        # Set up the course offering
        self.setup_course_offering()

        # Get the number of redemptions before the execution
        get_redeem_left_q = f'SELECT buy_num_remaining_redemptions FROM Buys WHERE customer_id = {self.customer_id}'
        before_redemptions = self.execute_query(get_redeem_left_q)[0][0]

        # Add the credit card
        args = ('2021-01-21', str(self.course_id), '1',
                str(self.customer_id), 'Redemption')
        q = self.generate_query('register_session', args)
        self.execute_query(q)

        # Nothing should be added to redeems
        q = 'SELECT * FROM Redeems'
        res = self.execute_query(q)
        assert len(res) == 1, f"Wrong Entries in redeems {res}"

        # The registration should be added
        q = 'SELECT * FROM Registers'
        res = self.execute_query(q)
        assert len(res) == 0, f"Wrong entries in registers {res}"

        after_redemptions = self.execute_query(get_redeem_left_q)[0][0]
        assert before_redemptions - \
            1 == after_redemptions, "The number of redemptions should have decremented by 1"
