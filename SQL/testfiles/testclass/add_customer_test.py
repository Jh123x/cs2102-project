import unittest
from . import BaseTest
from psycopg2.errors import UniqueViolation, CheckViolation, InvalidTextRepresentation


class DAddCustomerTest(BaseTest, unittest.TestCase):

    def test_add_customer_success(self):
        """Check if the customer is added correctly"""
        args = ("Invoker", "987354312", "address here",
                "test@test.com", '1234123412341234', '123', '2020-04-20')
        query = self.generate_query('add_customer', args)
        res = self.execute_query(query)

        # Check if it returns an id correctly
        assert len(res) > 0 and res[0][0] == 1, "Customer id is invalid {res}"

    def test_duplicate_customer_diff_card_fail(self):
        """Add the same customer with a different credit card"""
        # Check the arguments
        args = ("Invoker", "987354312", "address here",
                "test@test.com", '1234123412341234', '123', '2020-04-20')
        query = self.generate_query('add_customer', args)
        res = self.execute_query(query)

        # Check if it returns an id correctly
        assert len(res) > 0 and res[0][0] == 2, "Customer id is invalid {res}"

        # add the same customer but with a different credit card
        args = ("Invoker", "987354312", "address here",
                "test@test.com", '1234123412341235', '123', '2020-04-20')
        query = self.generate_query('add_customer', args)
        self.check_fail_test(
            query, "There is suppose to be a unique violation as the customer's information is the same", (UniqueViolation, ))

    def test_duplicate_customer_fail(self):
        """Check if adding the same customers will result in a failure"""

        # Args for adding the first customer
        args = ("Invoker", "987354312", "address here",
                "test@test.com", '1234123412341234', '123', '2020-04-20')
        query = self.generate_query('add_customer', args)
        res = self.execute_query(query)

        # Check if it returns an id correctly
        assert len(res) > 0 and res[0][0] == 4, "Customer id is invalid {res}"

        # Add the same customer again
        self.check_fail_test(
            query, 'It is suppose to throw the error', (UniqueViolation, ))

    def test_invalid_email_fail(self):
        """Check if the customer can be added with invalid email address"""
        args = ("Invoker", "987354312", "address here",
                "test@estcom", '1234123412341234', '123', '2020-04-20')
        query = self.generate_query('add_customer', args)
        self.check_fail_test(query, "Invalid email used should throw an exception", (CheckViolation, ))

    def test_invalid_phone_fail(self):
        """Check if the customer can be added with invalid phone number"""
        args = ("Invoker", "987354312asdf", "address here",
                "test@test.com", '1234123412341234', '123', '2020-04-20')
        query = self.generate_query('add_customer', args)
        self.check_fail_test(query, "Invalid phone used should throw an exception", (InvalidTextRepresentation, ))
