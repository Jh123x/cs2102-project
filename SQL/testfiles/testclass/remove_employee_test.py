import unittest
import datetime
from .basetest import BaseTest
from psycopg2.errors import RaiseException


class BRemoveEmployeeTest(BaseTest, unittest.TestCase):

    def test_remove_manager(self) -> None:
        """Remove the manager"""
        # Add a manager in
        self._add_person("Manager")

        # Check if the manager is added
        out = self.execute_query('SELECT * FROM Employees')
        assert len(out) == 1, out

        args = ('12', '2020-12-21')
        query = self.generate_procedure('remove_employee', args)
        res = self.execute_query(query)

        # Nothing should be returned at the cursor
        assert res == None

        # Check if there are any employees left
        expected = (12, "John", "address", '987654321', 'test@test.com', datetime.datetime.strptime("2020-05-03", "%Y-%m-%d"), datetime.datetime.strptime("2020-12-21", "%Y-%m-%d"))
        self.value_test('SELECT * FROM Employees', expected)


    def test_remove_non_existent(self) -> None:
        """Remove someone who does not exist"""

        # Remove someone who is not in the list
        args = ['-3', '2020-04-21']
        query = self.generate_procedure('remove_employee', tuple(args))
        self.check_fail_test(query, "Test is suppose to fail", (RaiseException,))

    def test_remove_manager_managing(self) -> None:
        """Remove a manager who has a role"""
        self._add_person('Manager', "ARRAY['Database']")
        
        # Check if the manager is added
        out = self.execute_query('SELECT * FROM Employees WHERE employee_id = 13')
        assert len(out) == 1, out

        args = ('13', '2020-12-21')
        query = self.generate_procedure('remove_employee', args)
        res = self.check_fail_test(query, "Not suppose to be able to remove a manager that is managing", (RaiseException,))

        # Nothing should be returned at the cursor
        assert res == None

        
    