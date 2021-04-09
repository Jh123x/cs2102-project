import unittest
from . import BaseTest
from unittest import expectedFailure
from psycopg2.errors import RaiseException


class ZGetMyCoursePackage(BaseTest, unittest.TestCase):
    def test_customer_does_not_exists(self):
        """Should return empty if the customer does not exist"""
        q = self.generate_query("get_my_course_package", ("1",))
        self.check_fail_test(q, 'The function should throw an exception if there is an error', RaiseException)

    def setup_vars(self):
        """Set up the variables to test the files"""

        # Add a customer
        self.customer_id = self._add_customer('John', 'addr', 987654321, 'test@test.com',
                                              '1234123412341234', '123', '2025-05-21')

        # Add course packages
        self.id1 = self._add_course_package(
            'Best package 1', 2, '2020-01-10', '2025-01-10', 20)
        self.id2 = self._add_course_package(
            'Best pacakge 2', 1, '2020-01-01', '2025-01-01', 10)
        self.id3 = self._add_course_package(
            'Worst Package', 0, '2021-01-01', '2022-02-01', 1)

    def test_customer_with_no_packages(self):
        """Should return empty when the customer has no packages"""
        # Set up vars
        self.setup_vars()

        # Execute the query
        q = self.generate_query('get_my_course_package', (str(self.customer_id),))
        res = self.execute_query(q)

        assert res == [({},)], f'The customer has no packages {res}'

    def test_customer_with_1_package(self):
        """Return the 1 active package that the customer has"""
        # Set up variables
        self.setup_vars()

        # Buy 1 package
        self._buy_package(self.customer_id, self.id1)

        # Execute the query
        q = self.generate_query('get_my_course_package', (str(self.customer_id),))
        res = self.execute_query(q)

        # Check the length of output
        assert len(res) == 1, f'The customer has no packages {res}'

        expected = {'package_name': 'Best package 1', 'package_price': 20.0, 'redeemed_sessions': [], 'buy_num_remaining_redemptions': 2, 'package_num_free_registrations': 2}

        # Remove the time component
        res = res[0][0]
        del res['buy_timestamp']

        # Check if the remaining is the same
        assert res == expected, f"Expected {expected}\nOutput{res}"
        

    @expectedFailure
    def test_customer_with_many_packages(self):
        """Return the many packages that the customer has"""
        # Set up variables
        self.setup_vars()

        # Buy the package that has 0 slots left
        self._buy_package(self.customer_id, self.id3)

        # Execute the query
        q = self.generate_query('get_my_course_package', (str(self.customer_id),))
        res = self.execute_query(q)
        assert len(res) == 1, f"There are no active packages {res}"
        assert res == [({},)], f"Result should be empty {res}"

        # Buy 1st packages
        self._buy_package(self.customer_id, self.id1)

        # Execute the query
        q = self.generate_query('get_my_course_package', (str(self.customer_id),))
        res = self.execute_query(q)
        assert len(res) == 1, f"There are no active packages {res}"
        expected = {'package_name': 'Best package 1', 'package_price': 20.0, 'redeemed_sessions': [], 'buy_num_remaining_redemptions': 2, 'package_num_free_registrations': 2}

        # Remove the time component
        res = res[0][0]
        del res['buy_timestamp']

        # Check if the remaining is the same
        assert res == expected, f"Expected {expected}\nOutput{res}"

        # Buy 2nd package
        self._buy_package(self.customer_id, self.id2)

        # Execute the query
        q = self.generate_query('get_my_course_package', (str(self.customer_id),))
        res = self.execute_query(q)

        assert len(res) == 2, f'The customer has incorrect number of packages {res}'