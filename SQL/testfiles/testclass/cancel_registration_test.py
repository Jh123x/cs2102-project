import unittest
import datetime
from . import BaseTest
from decimal import Decimal
from unittest import expectedFailure
from psycopg2.errors import RaiseException


class ZCancelRegistrationTest(BaseTest, unittest.TestCase):

    def test_invalid_customer_id(self):
        """Test the input on invalid customer id"""
        args = ('1','1','2020-01-01')
        q = self.generate_query('cancel_registration', args)
        self.check_fail_test(q, 'Invalid customer should result in an error', RaiseException)


    def setup_vars(self):
        """Set up the variables for this test"""
        # Add a manager
        self.manager_id = self._add_person('Manager', "Array['Database']")
        self.manager_id1 = self._add_person('Manager', "Array['Network']")

        # Add an instructor
        self.instructor_id = self._add_person('Instructor', "Array['Database']")
        self.instructor_id1 = self._add_person('Instructor', "Array['Network']")

        # Add an admin
        self.admin_id = self._add_person('Admin')

        # Add a course
        self.course_id = self._add_course('Database', 1)
        self.course_id1 = self._add_course('Network', 1, 'Networking')

        # Add a room
        self.room_id = 1
        self._add_room(1, 'Test room', 20)

        # Add a customer
        self.customer_id = self._add_customer('Test1', "test", 987654321, 'test@test.com', '1234123412341234', '123', '2025-05-31')

        # Add a course offering
        self.course_offering = self._add_course_offering('2021-01-21', 10, [('2021-06-21', 9, self.room_id), ('2021-06-21', 11, self.room_id)], '2021-05-31', 20, self.course_id, self.admin_id)
        self.course_offering1 = self._add_course_offering('2021-02-21', 10, [('2021-06-22', 14, self.room_id), ('2021-06-22', 16, self.room_id)], '2021-05-25', 20, self.course_id1, self.admin_id)

        # Add a package
        self.package_id = self._add_course_package('Best package', 10, '2020-06-20', '2025-06-20', 10)

        # Customer buys a package
        args = (str(self.customer_id), str(self.package_id))
        q = self.generate_query('buy_course_package', args)
        self.execute_query(q)

    def register_session(self):
        # Register for a package
        args = ('2021-01-21', str(self.course_id), '1', str(self.customer_id), 'Credit Card')
        q = self.generate_query('register_session', args)
        self.execute_query(q)

    def redeem_session(self):
        args = ('2021-01-21', str(self.course_id), '1', str(self.customer_id), 'Redemption')
        q = self.generate_query('register_session', args)
        self.execute_query(q)


    def test_register_cancels_successful(self):
        """Check if the registration is cancelled successfully"""
        self.setup_vars()
        self.register_session()

        # Check the registers before cancellation
        qr = 'SELECT * FROM Registers'
        res = self.execute_query(qr)
        assert len(res) == 1 and len(res[0]) > 1, f"Customer was not registered properly"
        assert not res[0][-1], "The cancel status should be false"

        # Check the cancels table
        qc = 'SELECT * FROM Cancels'
        res = self.execute_query(qc)
        assert len(res) == 0, f"There should be nothing in the cancels table {res}"

        # Cancel the registration
        args = (str(self.customer_id), str(self.course_id), '2021-01-21')
        time = datetime.datetime.now() + datetime.timedelta(hours=-8)
        q = self.generate_query('cancel_registration', args)
        self.execute_query(q) #No return


        # Check the cancels table
        res = self.execute_query(qc)
        assert len(res) == 1, "There should be an entry in the cancels table"
        expected = [(time, Decimal('9.00'), None, self.course_id, 1, datetime.date(2021, 1, 21), self.customer_id)]
        assert res[0][1:] == expected[0][1:], f"The res is not expected {res}\n{expected}"
        assert self.time_cmp(expected[0][0], res[0][0]), f"The time is not close to one another {res}\n{expected}"

        # Check the registration after cancellation
        res = self.execute_query(qr)
        assert len(res) == 1 and len(res[0]) > 1, f"Customer was removed from registers"
        assert res[0][-1], f"The cancel status should be True {res}"

    def test_redeems_cancels_successful(self):
        """Check if the registration is cancelled successfully"""
        self.setup_vars()
        self.redeem_session()

        # Check the registers before cancellation
        qr = 'SELECT * FROM Redeems'
        res = self.execute_query(qr)
        assert len(res) == 1 and len(res[0]) > 1, f"Customer was not redeemed properly"
        assert not res[0][-1], "The cancel status should be false"

        # Check the cancels table
        qc = 'SELECT * FROM Cancels'
        res = self.execute_query(qc)
        assert len(res) == 0, f"There should be nothing in the cancels table {res}"

        # Cancel the registration
        args = (str(self.customer_id), str(self.course_id), '2021-01-21')
        time = datetime.datetime.now() + datetime.timedelta(hours=-8)
        q = self.generate_query('cancel_registration', args)
        self.execute_query(q) #No return


        # Check the cancels table
        res = self.execute_query(qc)
        assert len(res) == 1, "There should be an entry in the cancels table"
        expected = [(time, None, 1, self.course_id, 1, datetime.date(2021, 1, 21), self.customer_id)]
        assert res[0][1:] == expected[0][1:], f"The res is not expected {res}"
        assert self.time_cmp(expected[0][0], res[0][0]), f"The time is not close to one another {res}\n{expected}"

        # Check the registration after cancellation
        res = self.execute_query(qr)
        assert len(res) == 1 and len(res[0]) > 1, f"Customer was removed from redeems"
        assert res[0][-1], f"The cancel status should be True {res}"
