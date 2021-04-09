import unittest
import datetime
from . import BaseTest


class ZViewSummaryReportTest(BaseTest, unittest.TestCase):
    def setup_vars(self):
        """Set up the variables for view_summary_report"""
        # Add Full time positions
        self.manager_id = self._add_person("Manager", "ARRAY['Database', 'OS']", 30)
        self.admin_id = self._add_person("Admin", salary=40)
        self.full_instructor_id = self._add_person(
            "Instructor", "ARRAY['Database']", 20
        )

        # Add Part time instructor
        self.part_instructor_id = self._add_part_time_instr("ARRAY['OS']", 10)

        # Add courses
        self.course_id1 = self._add_course("Database", 1, "Database")
        self.course_id2 = self._add_course("OS", 1, "OS")

        # Add room
        self.room_id = self._add_room(1, 'Test room', 20)

        # Add course offerings
        self.course_offering1 = self._add_course_offering('2021-01-21', 10, [('2021-06-21', 9, self.room_id), ('2021-06-21', 11, self.room_id)], '2021-05-31', 20, self.course_id1, self.admin_id)
        self.course_offering2 = self._add_course_offering('2021-01-21', 10, [('2021-06-22', 9, self.room_id), ('2021-06-22', 11, self.room_id)], '2021-05-31', 20, self.course_id2, self.admin_id)
        self.course_offering3 = self._add_course_offering('2021-01-22', 10, [('2021-04-27', 9, self.room_id), ('2021-04-27', 11, self.room_id)], '2021-04-16', 20, self.course_id2, self.admin_id)

        # Add customers
        self.customer_id1 = self._add_customer('Test1', "test", 987654321, 'test@test.com', '1234123412341234', '123', '2025-05-31')
        self.customer_id2 = self._add_customer('Test2', "test", 987654321, 'test@test.com', '1234123412341235', '123', '2025-05-31')
        self.customer_id3 = self._add_customer('Test3', "test", 987654321, 'test@test.com', '1234123412341236', '123', '2025-05-31')

        # Register sessions
        self._register_credit_card('2021-01-21', self.course_id1, 1, self.customer_id1)
        self._register_credit_card('2021-01-21', self.course_id1, 1, self.customer_id2)
        self._register_credit_card('2021-01-21', self.course_id1, 1, self.customer_id3)

        # Add course packages
        self.package1 = self._add_course_package("Best Package", 2, '2021-03-01', '2021-08-02', 50)
        self.package2 = self._add_course_package("Medium Package", 1, '2021-03-01', '2021-08-02', 50)
        self.package3 = self._add_course_package("Worst Package", 1, '2021-03-01', '2021-08-02', 100)

        # Buy course packages
        self._buy_package(self.customer_id1, self.package1)
        self._buy_package(self.customer_id2, self.package2)
        self._buy_package(self.customer_id3, self.package3)

        # Redeem sessions
        self._register_redeems('2021-01-21', self.course_id2, 1, self.customer_id1)
        self._register_redeems('2021-01-21', self.course_id2, 1, self.customer_id2)
        self._register_redeems('2021-01-21', self.course_id2, 1, self.customer_id3)

        # Cancel registrations
        self._cancel_registration(self.customer_id1, self.course_id1)
        self._cancel_registration(self.customer_id2, self.course_id2)

        # Prepare PaySlips
        qps = self.generate_query("pay_salary", ())
        self.execute_query(qps)

    def test_view_summary_report_with_nothing(self):
        """View summary report with nothing inside"""

        # View past 1 report with nothing
        q = self.generate_query('view_summary_report', ('1',))
        res = self.execute_query(q)
        assert len(res) == 1, f'There is suppose to be a summary report with no value {res}'
        expected = [(f'({datetime.datetime.now().month},{datetime.datetime.now().year},0.00,0.00,0.00,0.00,0)',)]
        assert res == expected, f"Summary report is suppose to be {expected}\nGot {res} instead"

        # View past 2 reports with nothing
        q = self.generate_query('view_summary_report', ('2',))
        res = self.execute_query(q)
        assert len(res) == 2, f'There is suppose to be a summary report with no value {res}'
        expected = [
            (f'({datetime.datetime.now().month},{datetime.datetime.now().year},0.00,0.00,0.00,0.00,0)',),
            (f'({datetime.datetime.now().month - 1},{datetime.datetime.now().year},0.00,0.00,0.00,0.00,0)',),
            ]
        assert res == expected, f"Summary report is suppose to be {expected}\nGot {res} instead"


    def test_view_summary_report_success(self):
        """Check if summary report is working correctly"""

        # Setup variables
        self.setup_vars()

        q = self.generate_query("view_summary_report", ('1',))
        res = self.execute_query(q)
        expected = [(f'({datetime.datetime.now().month},{datetime.datetime.now().year},110.00,200.00,30.00,9.00,2)',)]
        assert res == expected, f'\nOutput:   {res}\nExpected: {expected}'
