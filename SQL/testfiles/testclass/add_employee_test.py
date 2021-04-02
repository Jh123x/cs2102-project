import unittest
from datetime import datetime
from .basetest import BaseTest


class AddEmployeeTest(BaseTest, unittest.TestCase):

    def test_add_admin_success(self) -> None:
        """Test if the full time employee is added correctly"""

        # Execute query to add admin
        args = ["jane", "address", '987654321', 'test@test.com', '2020-05-03', 'Admin', "Full-Time", '20.5']
        admin_query = self.generate_query("add_employee", tuple(args))
        self.execute_query(admin_query)

        # Check if the admin is correctly added to all tables
        expected_employees = [(1, "jane", "address", '987654321', 'test@test.com', datetime.strptime('2020-05-03', r'%Y-%m-%d').date(),None)]
        self.value_test('SELECT * FROM Employees', expected_employees, f"Unexpected values of {expected_employees} found instead of %s")

        # Checking if the person is in the admins table (Get the id of Jane)
        expected_admin = [(1,)]
        self.value_test('SELECT * FROM Administrators', expected_admin, f"Unexpected admin ids {expected_admin} instead of %s")

        # Checking if the person is added in full time table
        expected_full_time = [(1, 20.5)]
        self.value_test('SELECT * FROM FullTimeEmployees', expected_full_time, f"Unexpected full time ids {expected_admin} instead of %s")


    def test_add_pinstructor_success(self) -> None:
        """Test if the part time employee is added correctly"""

        # Execute the query
        args = ["ivan", "address", '987654321', 'test@test.com', '2020-05-03', 'Instructor', "part-time", '10.5', "Array['Database']::TEXT"]
        pt_instructor_query = self.generate_query("add_employee", tuple(args))
        self.execute_query(pt_instructor_query)

        #Check if the Instructors Table is
        expected_employees = [(1, "ivan", "address", '987654321', 'test@test.com', datetime.strptime('2020-05-03', r'%Y-%m-%d').date(), ['Database'])]
        self.value_test('SELECT * FROM Employees', expected_employees, f"Unexpected values of {expected_employees} found instead of %s")

    def test_add_instructor_success(self) -> None:
        """Test if the fulltime instructor is added correctly"""
        pass

        




