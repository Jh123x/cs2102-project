import unittest
import datetime
from time import sleep
from . import BaseTest
from psycopg2.errors import IntegrityError, UniqueViolation


class EUpdateCreditCardTest(BaseTest, unittest.TestCase):

    def _add_customer(self, name: str, card: int) -> int:
        """Add a customer to the table"""
        args = (name, "address here", "987354312",
                "test@test.com", card, '123', '2020-04-20')
        query = self.generate_query('add_customer', args)
        res = self.execute_query(query)

        # Check if it returns an id correctly
        assert len(res) > 0, "Customer not added correctly."
        return res[0][0]

    def test_update_success(self):
        """Update credit card for a person"""
        id = self._add_customer("Invoker", '1234123412341234')
        args = (str(id), '1234123412341235', '125', '2020-04-25')
        query = self.generate_query('update_credit_card', args)
        self.execute_query(query)

        # Check if the credit card is updated in the table
        query = f'SELECT * FROM CreditCards'
        expected = [
            ('1234123412341235', '125', datetime.datetime.strptime(
                '2020-04-25', "%Y-%m-%d").date()),
            ('1234123412341234', '123', datetime.datetime.strptime(
                '2020-04-20', "%Y-%m-%d").date())
        ]
        res = self.execute_query(query)

        assert set(res) == set(
            expected), f"Expected: {expected}\n Result: {res}"

        # Check if the owns table is updated correctly
        query = f"SELECT * FROM Owns"
        today = datetime.datetime.combine(
            datetime.datetime.now().date(), datetime.time(0))
        expected = [
            (id, '1234123412341235', today),
            (id, '1234123412341234', today)
        ]
        res = self.execute_query(query)
        assert set(res) == set(
            expected), f"Expected: {expected}\n Result: {res}"

    def test_update_to_another_user_card_fail(self):
        """Update to another person's card"""
        id1 = self._add_customer('Invoker', '1234123412341234')
        _ = self._add_customer('Warchief', '1234123412341235')

        # Ensure both customers are added correctly
        query = 'SELECT * FROM Customers'
        res = self.execute_query(query)
        assert len(res) == 2, "The customers are not added correctly"

        # Update one to the number of the next
        args = (str(id1), '1234123412341235', '123', '2020-04-25')
        query = self.generate_query('update_credit_card', args)
        self.check_fail_test(
            query, "Cannot update the card of another person", (IntegrityError,))

    def test_update_to_same_card_fail(self):
        """Update to same card error"""
        id1 = self._add_customer('Invoker', '1234123412341234')

        # Ensure both customers are added correctly
        query = 'SELECT * FROM Customers'
        res = self.execute_query(query)
        assert len(res) == 1, "The customer are not added correctly"

        args = (str(id1), "1234123412341234", '123', '2020-04-20')
        query = self.generate_query('update_credit_card', args)
        self.check_fail_test(query, "Cannot update to the same card", (UniqueViolation,))
