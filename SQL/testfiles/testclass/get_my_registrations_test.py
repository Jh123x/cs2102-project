import unittest
from . import BaseTest
from unittest import expectedFailure
from psycopg2.errors import RaiseException


class ZGetMyRegistrationsTest(BaseTest, unittest.TestCase):

    def test_invalid_customer(self):
        """Invalid customer should return empty table"""
        q = self.generate_query('get_my_registrations', ('1',))
        self.check_fail_test(q, 'Invalid customer id is suppose to raise exception', RaiseException)

    def test_valid_customer_with_no_registrations(self):
        """Valid customer with no registration should return empty table"""
        self.customer_id = self._add_customer('John', 'addr', 987654312, "test@test.com", '1234123412341234', '789', '2025-05-19')
        q = self.generate_query('get_my_registrations', (str(self.customer_id), ))
        res = self.execute_query(q)

        assert len(res) == 0, f"The customer has no registrations {res}"

    @expectedFailure
    def test_valid_customer_with_registrations(self):
        """Test if registration returns the correct value"""
        raise NotImplementedError('This test is not implemented')


    @expectedFailure
    def test_valid_customer_with_some_registrations(self):
        """Test if the customer with some registrations get the correct course"""
        raise NotImplementedError('This test is not implemented')