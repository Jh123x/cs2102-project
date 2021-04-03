import unittest
from psycopg2.errors import RaiseException, ForeignKeyViolation, CheckViolation
from datetime import datetime
from .basetest import BaseTest


class AddEmployeeTest(BaseTest, unittest.TestCase):

    def test_add_admin_success(self) -> None:
        """Test if the full time employee is added correctly"""

        # Execute query to add admin
        args = ["jane", "address", '987654321', 'test@test.com',
                '2020-05-03', 'Admin', "Full-Time", '20.5']
        admin_query = self.generate_query("add_employee", tuple(args))
        self.execute_query(admin_query)

        # Check if the admin is correctly added to all tables
        expected_employees = [(1, "jane", "address", '987654321', 'test@test.com',
                               datetime.strptime('2020-05-03', r'%Y-%m-%d').date(), None)]
        self.value_test('SELECT * FROM Employees', expected_employees)

        # Checking if the person is in the admins table (Get the id of Jane)
        expected_admin = [(1,)]
        self.value_test('SELECT * FROM Administrators', expected_admin)

        # Checking if the person is added in full time table
        expected_full_time = [(1, 20.5)]
        self.value_test('SELECT * FROM FullTimeEmployees', expected_full_time)

    def _add_manager(self) -> None:
        """Add a manager into the table"""
        args = ["John", "address", '987654321', 'test@test.com',
                '2020-05-03', 'Manager', "full-time", '10.5', "Array['Database']"]
        manager_query = self.generate_query("add_employee", tuple(args))
        self.execute_query(manager_query)

    def test_add_manager_success(self) -> None:
        """Test if the Manager is added correctly"""
        self._add_manager()

        # Check if the admin is correctly added to all tables
        expected_employees = [(7, "John", "address", '987654321', 'test@test.com',
                               datetime.strptime('2020-05-03', r'%Y-%m-%d').date(), None)]
        self.value_test('SELECT * FROM Employees', expected_employees)

        # Checking if the person is in the admins table (Get the id of Jane)
        expected_manager = [(7,)]
        self.value_test('SELECT * FROM Managers', expected_manager)

        # Checking if the person is added in full time table
        expected_full_time = [(7, 10.5)]
        self.value_test('SELECT * FROM FullTimeEmployees', expected_full_time)

    def test_add_pinstructor_success(self) -> None:
        """Test if the part time employee is added correctly"""

        # Add the manager
        self._add_manager()

        # Execute the query
        args = ["ivan", "address", '987654321', 'test@test.com', '2020-05-03',
                'Instructor', "part-time", '15.5', "Array['Database']"]
        pt_instructor_query = self.generate_query("add_employee", tuple(args))
        self.execute_query(pt_instructor_query)

        # Check if the Employees Table is correct
        expected_employees = [
            (8, "John", "address", '987654321', 'test@test.com',
             datetime.strptime('2020-05-03', r'%Y-%m-%d').date(), None),
            (9, "ivan", "address", '987654321', 'test@test.com',
             datetime.strptime('2020-05-03', r'%Y-%m-%d').date(), None)
        ]
        self.value_test('SELECT * FROM Employees', expected_employees)

        # Check if the employee is in instructors
        expected_instructors = [(9,)]
        self.value_test('SELECT * FROM Instructors', expected_instructors)

        # Check if the instructor is in part-time table
        expected_part_time = [(9, 15.5)]
        self.value_test('SELECT * FROM PartTimeEmployees', expected_part_time)

    def test_add_instructor_success(self) -> None:
        """Test if the fulltime instructor is added correctly"""

        # Add the manager
        self._add_manager()

        # Execute the query
        args = ["ivan", "address", '987654321', 'test@test.com', '2020-05-03',
                'Instructor', "full-time", '15.5', "Array['Database']"]
        ft_instructor_query = self.generate_query("add_employee", tuple(args))
        self.execute_query(ft_instructor_query)

        # Check if the Employees Table is correct
        expected_employees = [
            (3, "John", "address", '987654321', 'test@test.com',
             datetime.strptime('2020-05-03', r'%Y-%m-%d').date(), None),
            (4, "ivan", "address", '987654321', 'test@test.com',
             datetime.strptime('2020-05-03', r'%Y-%m-%d').date(), None)
        ]
        self.value_test('SELECT * FROM Employees', expected_employees)

        # Check if the employee is in instructors
        expected_instructors = [(4,)]
        self.value_test('SELECT * FROM Instructors', expected_instructors)

        # Check if the instructor is in part-time table
        expected_part_time = [(3, 10.5), (4, 15.5)]
        self.value_test('SELECT * FROM FullTimeEmployees', expected_part_time)

    def test_add_ptadmin_fail(self) -> None:
        args = ["ivan", "address", '987654321', 'test@test.com', '2020-05-03',
                'Admin', "part-time", '15.5']
        query = self.generate_query("add_employee", tuple(args))
        self.check_fail_test(
            query, "Test case is suppose to fail but it passed", (RaiseException,))

    def test_add_ptmanager_fail(self) -> None:
        """Test fails after adding parttime manage"""
        args = ["ivan", "address", '987654321', 'test@test.com', '2020-05-03',
                'Manager', "part-time", '15.5', "Array['Database']"]
        query = self.generate_query("add_employee", tuple(args))
        self.check_fail_test(
            query, "Test case is suppose to fail but it passed", (RaiseException,))

    def test_add_invalid_email_fail(self) -> None:
        args = ["ivan", "address", '987654321', 'testtest.com', '2020-05-03',
                'Admin', "full-time", '15.5', ]
        query = self.generate_query("add_employee", tuple(args))
        self.check_fail_test(
            query, "Test case is suppose to fail but it passed", (CheckViolation,))

    def test_add_invalid_phone_fail(self) -> None:
        # Execute the query
        args = ["ivan", "address", 'asfsaf987654321', 'test@test.com', '2020-05-03',
                'Admin', "full-time", '15.5']
        query = self.generate_query("add_employee", tuple(args))
        self.check_fail_test(
            query, "Test case is suppose to fail but it passed", (CheckViolation,))

    def test_add_course_area_with_no_manager_fail(self) -> None:
        # Execute the query
        args = ["ivan", "address", '987654321', 'test@test.com', '2020-05-03',
                'Instructor', "full-time", '15.5', "Array['Network']"]
        query = self.generate_query("add_employee", tuple(args))
        self.check_fail_test(
            query, "Test case is suppose to fail but it passed", (ForeignKeyViolation,))
