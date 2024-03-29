import unittest
from . import BaseTest
from psycopg2.errors import UniqueViolation, CheckViolation, InvalidTextRepresentation


class DAddCustomerTest(BaseTest, unittest.TestCase):
    def setUp(self) -> None:
        self.args = ["Invoker", "address here", "987354312",
                "test@test.com", '1234123412341234', '123', '2025-04-20']
        return super().setUp()

    def test_add_customer_success(self):
        """Check if the customer is added correctly"""
        query = self.generate_query('add_customer', self.args)
        res = self.execute_query(query)

        # Check if it returns an id correctly
        assert len(res) > 0 and res[0][0] == 1, "Customer id is invalid {res}"

    def test_duplicate_customer_diff_card_success(self):
        """Add the same customer with a different credit card"""
        # Check the arguments
        query = self.generate_query('add_customer', self.args)
        res = self.execute_query(query)

        # Check if it returns an id correctly
        assert len(res) > 0 and res[0][0] == 2, "Customer id is invalid {res}"

        # add the same customer but with a different credit card
        self.args[4] = '1234123412341235'
        query = self.generate_query('add_customer', self.args)
        self.execute_query(query)

        # Get the table entries
        query = 'SELECT * FROM Customers'
        res = self.execute_query(query)
        assert len(res) == 2, "Customers not added in correctly"
        assert res[0] != res[1], "Customers are not exactly the same"


    def test_duplicate_customer_success(self):
        """Check if adding the same customers will result in a success"""

        # Args for adding the first customer
        query = self.generate_query('add_customer', self.args)
        res = self.execute_query(query)

        # Check if it returns an id correctly
        assert len(res) > 0 and res[0][0] == 4, f"Customer id is invalid {res}"

        # Add the same customer again
        self.check_fail_test(query, "Duplicate credit cards are supposed to fail", (UniqueViolation,))

    def test_invalid_email_fail(self):
        """Check if the customer can be added with invalid email address"""
        self.args[3] = "test@estcom"
        query = self.generate_query('add_customer', self.args)
        self.check_fail_test(query, "Invalid email used should throw an exception", (CheckViolation, ))

    def test_invalid_phone_fail(self):
        """Check if the customer can be added with invalid phone number"""
        self.args[2] = '987354312asdf'
        query = self.generate_query('add_customer', self.args)
        self.check_fail_test(query, "Invalid phone used should throw an exception", (InvalidTextRepresentation, ))
