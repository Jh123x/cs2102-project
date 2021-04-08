import unittest
from . import BaseTest
from unittest import expectedFailure


class PaySalaryTest(BaseTest, unittest.TestCase):
    def setUp(self):
        """Set up the variables for pay_salary"""
        # Add Full time positions
        self.manager_id = self._add_person("Manager", "ARRAY['Database']", 30)
        self.admin_id = self._add_person("Admin", salary=40)
        self.full_instructor_id = self._add_person(
            "Instructor", "ARRAY['Database']", 20
        )

        # Add Part time instructor
        self.part_instructor_id = self._add_part_time_instr("ARRAY['Database']", 5)

        return super().setUp()

    def test_pay_salary_success(self):
        """Check if pay salary is working correctly"""
        # Pay salary, returns the table of salaries paid
        q = self.generate_query("pay_salary", ())
        res = self.execute_query(q)

        assert len(res) == 4, "The number of employees is not correct"
        expected = [
            # Part time with 0 hours paid 0
            (f"({self.part_instructor_id},John,part-time,,0,5.00,,0.00)",),
            (f"({self.manager_id},John,full-time,30,,,30.00,30.0000000000000000)",),
            (f"({self.admin_id},John,full-time,30,,,40.00,40.0000000000000000)",),
            (
                f"({self.full_instructor_id},John,full-time,30,,,20.00,20.0000000000000000)",
            ),
        ]
        assert (
            res == expected
        ), f"Payslip is working incorrectly {res}\nExpected: {expected}"

    @expectedFailure
    def test_pay_salary_prorated_success(self):
        """Test the pro-rated salary of an employee if they just joined"""
        raise NotImplementedError("This test is not implemented")
