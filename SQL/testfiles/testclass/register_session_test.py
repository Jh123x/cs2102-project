import unittest
from . import BaseTest
from unittest import expectedFailure
from psycopg2.errors import RaiseException


class ZRegisterSessionTest(BaseTest, unittest.TestCase):
    def test_invalid_resgistration_input(self):
        """Invalid registration input"""
        args = ("2020-04-21", "1", "1", "1", "Credit Card")
        q = self.generate_query("register_session", args)
        self.check_fail_test(q, "Invalid input should raise an exception", RaiseException)

    def test_invalid_payment_type(self):
        """Invalid payment method"""
        args = ("2020-04-21", "1", "1", "1", "Invalid Payment Method")
        q = self.generate_query("register_session", args)
        self.check_fail_test(
            q, "Invalid payment method should not pass the test case", RaiseException
        )
