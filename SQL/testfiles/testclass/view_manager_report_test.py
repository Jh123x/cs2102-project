import unittest
from . import BaseTest
from unittest import expectedFailure


class ZViewManagerReportTest(BaseTest, unittest.TestCase):
    def setup_vars(self):
        """Set up the variables for view_manager_report"""
        # Add Full time positions
        self.manager_id = self._add_person("Manager", "ARRAY['Database', 'OS', 'AI']", 30)
        self.admin_id = self._add_person("Admin", salary=40)
        self.full_instructor_id = self._add_person(
            "Instructor", "ARRAY['Database']", 20
        )

        # Add Part time instructor
        self.part_instructor_id = self._add_part_time_instr("ARRAY['OS']", 10)
        self.part_instructor_id = self._add_part_time_instr("ARRAY['AI']", 10)

        # Add courses
        self.course_id1 = self._add_course("Database", 1, "Database")
        self.course_id2 = self._add_course("OS", 1, "OS")
        self.course_id3 = self._add_course("AI", 1, "AI")

        # Add room
        self.room_id = self._add_room(1, 'Test room', 20)
        self.room_id2 = self._add_room(2, 'Test room 2', 20)

        # Add course offerings
        self.course_offering1 = self._add_course_offering('2021-01-21', 10, [('2021-06-21', 9, self.room_id), ('2021-06-21', 11, self.room_id)], '2021-05-31', 20, self.course_id1, self.admin_id)
        self.course_offering2 = self._add_course_offering('2021-01-21', 10, [('2021-06-22', 9, self.room_id), ('2021-06-22', 11, self.room_id)], '2021-05-31', 20, self.course_id2, self.admin_id)
        self.course_offering3 = self._add_course_offering('2021-01-21', 10, [('2021-06-22', 9, self.room_id2), ('2021-06-22', 11, self.room_id2)], '2021-05-31', 20, self.course_id3, self.admin_id)

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
        self.package2 = self._add_course_package("Medium Package", 2, '2021-03-01', '2021-08-02', 100)
        self.package3 = self._add_course_package("Worst Package", 2, '2021-03-01', '2021-08-02', 150)

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

    def test_no_one_in_db(self):
        """Test view manager report when there is no one in the db"""
        q = self.generate_query('view_manager_report', ())
        res = self.execute_query(q)
        expected = []
        assert len(res) == 0, f'There is suppose to be an empty summary {res}'
        assert res == expected, f'The result is suppose to be empty {res}'

    def test_managers_who_does_nothing(self):
        """Test managers who did nothing"""
        # Add 2 managers who do nothing
        self.manager_id = self._add_person("Manager", "ARRAY['Database']", 30)
        self.manager_id1 = self._add_person("Manager", "ARRAY['AI']", 30)

        # Run the query
        q = self.generate_query('view_manager_report', ())
        res = self.execute_query(q)
        assert len(res) == 2, f'There is suppose to be 2 entries {res}'

    def test_view_manager_report_only_one_highest_course(self):
        """Check if manager report is working correctly"""
        self.setup_vars()
        q = self.generate_query("view_manager_report", ())
        res = self.execute_query(q)
        expected = [('(John,3,3,121.00,{OS})',)]
        assert res == expected, f'\nOutput:   {res}\nExpected: {expected}'

    def test_view_manager_report_two_highest_courses(self):
        """Check if manager report is working correctly, with 2 highest courses"""
        self.setup_vars()
        # Let AI have the same registrations as OS
        # Register sessions
        self._register_redeems('2021-01-21', self.course_id3, 1, self.customer_id1)
        self._register_redeems('2021-01-21', self.course_id3, 1, self.customer_id3)

        q = self.generate_query("view_manager_report", ())
        res = self.execute_query(q)
        expected = [('(John,3,3,221.00,"{OS,AI}")',)]
        assert res == expected, f'\nOutput:   {res}\nExpected: {expected}'
