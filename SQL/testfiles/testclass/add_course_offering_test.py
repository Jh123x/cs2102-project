import unittest
from . import BaseTest
from psycopg2.errors import RaiseException, CheckViolation, UniqueViolation

class HAddCourseOfferingTest(BaseTest, unittest.TestCase):

    def _add_manager(self, name: str, areas: tuple):
        """Add a manager to the table with an area"""
        args = (
            name,
            "address",
            "123456789",
            "test@test.com",
            "2020-05-03",
            "Manager",
            "Full-time",
            "20.5",
            self.process_arr_args(areas),
        )
        query = self.generate_query("add_employee", args)
        res = self.execute_query(query)
        assert len(res) > 0, "Manager not added successfully"
        return res[0][0]

    def _add_instructor(self, name: str, time: str, areas: tuple):
        """Add an instructor to a table"""
        args = (
            name,
            "address",
            "123456789",
            "test@test.com",
            "2020-05-03",
            "Instructor",
            time,
            "20.5",
            self.process_arr_args(areas),
        )
        query = self.generate_query("add_employee", args)
        res = self.execute_query(query)
        assert len(res) > 0, "Instructor not added successfully"
        return res[0][0]

    def _add_course(self, name: str, area: str):
        """Add a course to the table
        course title, course description, course area, and duration
        """
        args = (name, "Description", area, "4")
        query = self.generate_query("add_course", args)
        res = self.execute_query(query)
        assert len(res) == 1, "Course is not added successfully"
        return res[0][0]

    def _add_admin(self, name: str):
        """Add an admin into the table"""
        args = (
            name,
            "address",
            "123456789",
            "test@test.com",
            "2020-05-03",
            "Admin",
            "Full-time",
            "20.5",
        )
        query = self.generate_query("add_employee", args)
        res = self.execute_query(query)
        assert len(res) > 0, "Admin not added successfully"
        return res[0][0]

    def add_rooms(self):
        """Add 2 rooms into the db"""
        # Add rooms
        query = f"INSERT INTO Rooms VALUES('1', 'Room1', '20') RETURNING room_id"
        self.rid = self.execute_query(query)[0][0]

        query = f"INSERT INTO Rooms VALUES('2', 'Room2', '20') RETURNING room_id"
        self.rid1 = self.execute_query(query)[0][0]

    def setUp(self) -> None:

        # Add Rooms
        self.add_rooms()

        # Add Manager
        self.manager_id = self._add_manager("Manager1", ("Database",))
        self.manager_id1 = self._add_manager("Manager2", ("Network",))

        # Add admin
        self.admin_id = self._add_admin("Admin1")

        # Add courses
        self.course_id = self._add_course("Database", "Database")
        self.course_id1 = self._add_course("Network", "Network")
        self.course_id2 = self._add_course("PSQL", "Database")

        self.instructor_ids = {}
        specialization = (("Database",), ("Network",))
        part_full_time = ("Part-Time", "Full-time")
        for index in range(3):
            spec = specialization[index % len(specialization)]
            t = part_full_time[index % 2]
            self.instructor_ids[index] = self._add_instructor(
                f"Instructor{index}", t, spec
            )
        return super().setUp()

    def test_add_course_offering(self):
        """Adding 2 different course offering should succeed"""

        # Add the course offering 1 time
        arr = self.make_session_array([('2021-05-04', '14', self.rid1), ('2021-06-04', '14', self.rid1)])
        args = ('2021-04-05','100.00', arr, '2021-04-20', '40', str(self.course_id), str(self.admin_id))
        query = self.generate_query("add_course_offering", args)
        res = self.execute_query(query)

        assert len(res) > 0, "Course Offering 1 not added successfully"

        expected =[(f"(2021-04-05,100.00,2021-04-20,40,40,{self.course_id},{self.admin_id},2021-05-04,2021-06-04)",)]
        assert res == expected, f'\nOutput:   {res}\nExpected: {expected}'

        arr = self.make_session_array([('2021-05-06', '14', self.rid), ('2021-06-03', '14', self.rid)])
        args = ('2021-04-06','100.00', arr, '2021-04-20', '40', str(self.course_id1), str(self.admin_id))
        query = self.generate_query("add_course_offering", args)
        res = self.execute_query(query)
        assert len(res) > 0, "Course Offering 1 not added successfully"

        expected =[(f"(2021-04-06,100.00,2021-04-20,40,40,{self.course_id1},{self.admin_id},2021-05-06,2021-06-03)",)]
        assert res == expected, f'\nOutput:   {res}\nExpected: {expected}'


    def test_add_same_course_offering_fail(self):
        # Add the course offering 1 time
        arr = self.make_session_array([('2021-05-04', '14', self.rid1), ('2021-06-04', '14', self.rid1)])
        args = ('2021-04-05','100.00', arr,'2021-04-20', '40', str(self.course_id), str(self.admin_id))
        query = self.generate_query("add_course_offering", args)
        res = self.execute_query(query)

        assert len(res) > 0, "Course Offering 1 not added successfully"

        expected =[(f"(2021-04-05,100.00,2021-04-20,40,40,{self.course_id},{self.admin_id},2021-05-04,2021-06-04)",)]
        assert res == expected, f'Output: {res}\nExpected: {expected}'

        res = self.check_fail_test(query, "Adding the same offering should fail", UniqueViolation)

    def test_add_course_offering_session_on_weekends_fail(self):
        # Add the course offering 1 time
        arr = self.make_session_array([('2021-05-09', '14', self.rid1), ('2021-06-12', '14', self.rid1)])
        args = ('2021-04-07','100.00', arr,'2021-04-20', '40', str(self.course_id), str(self.admin_id))
        query = self.generate_query("add_course_offering", args)
        res = self.check_fail_test(query, "Adding the offering with session on weekend should fail", CheckViolation)

    def test_add_course_offering_session_between_lunch_fail(self):
        # Add the course offering 1 time
        arr = self.make_session_array([('2021-05-09', '10', self.rid1), ('2021-06-12', '10', self.rid1)])
        args = ('2021-04-07','100.00', arr,'2021-04-20', '40', str(self.course_id), str(self.admin_id))
        query = self.generate_query("add_course_offering", args)
        res = self.check_fail_test(query, "Session time is out of range", RaiseException)

    def test_add_course_offering_session_room_in_use_fail(self):
        arr = self.make_session_array([('2021-05-06', '14', self.rid), ('2021-06-03', '14', self.rid)])
        args = ('2021-04-06','100.00', arr, '2021-04-20', '40', str(self.course_id1), str(self.admin_id))
        query = self.generate_query("add_course_offering", args)
        res = self.execute_query(query)
        assert len(res) > 0, "Course Offering 1 not added successfully"

        expected =[(f"(2021-04-06,100.00,2021-04-20,40,40,{self.course_id1},{self.admin_id},2021-05-06,2021-06-03)",)]
        assert res == expected, f'\nOutput:   {res}\nExpected: {expected}'

        # Add the course offering 1 time
        arr = self.make_session_array([('2021-05-06', '14', self.rid), ('2021-06-03', '14', self.rid)])
        args = ('2021-04-06','100.00', arr, '2021-04-20', '40', str(self.course_id), str(self.admin_id))
        query = self.generate_query("add_course_offering", args)
        res = self.check_fail_test(query, "Adding the offering with session room in use should fail", RaiseException)

    def test_add_course_offering_session_target_registration_more_than_capacity_fail(self):
        # Add the course offering 1 time
        arr = self.make_session_array([('2021-05-06', '14', self.rid), ('2021-06-03', '14', self.rid)])
        args = ('2021-04-06','100.00', arr, '2021-04-20', '60', str(self.course_id), str(self.admin_id))
        query = self.generate_query("add_course_offering", args)
        res = self.check_fail_test(query, "Adding the offering with number of target registration more than room capacity should fail", RaiseException)

    def test_add_course_offering_session_not_enough_instructors_fail(self):
        arr = self.make_session_array([('2021-05-06', '14', self.rid), ('2021-06-03', '14', self.rid)])
        args = ('2021-04-06','100.00', arr, '2021-04-20', '40', str(self.course_id), str(self.admin_id))
        query = self.generate_query("add_course_offering", args)
        res = self.execute_query(query)
        assert len(res) > 0, "Course Offering 1 not added successfully"

        expected =[(f"(2021-04-06,100.00,2021-04-20,40,40,{self.course_id},{self.admin_id},2021-05-06,2021-06-03)",)]
        assert res == expected, f'\nOutput:   {res}\nExpected: {expected}'

        # Add the course offering 1 time
        arr = self.make_session_array([('2021-05-06', '14', self.rid), ('2021-06-03', '14', self.rid)])
        args = ('2021-04-05','100.00', arr, '2021-04-20', '40', str(self.course_id2), str(self.admin_id))
        query = self.generate_query("add_course_offering", args)
        res = self.check_fail_test(query, "Adding the offering with sessions that has not enough instructors should fail", RaiseException)

    def test_add_course_offering_launch_date_after_registration_deadline_fail(self):
        # Add the course offering 1 time
        arr = self.make_session_array([('2021-05-06', '14', self.rid), ('2021-06-03', '14', self.rid)])
        args = ('2021-04-22','100.00', arr, '2021-04-20', '40', str(self.course_id2), str(self.admin_id))
        query = self.generate_query("add_course_offering", args)
        res = self.check_fail_test(query, "Adding the offering with launch date after registration deadline should fail", RaiseException)

    def test_add_course_offering_num_target_registration_negative_fail(self):
        # Add the course offering 1 time
        arr = self.make_session_array([('2021-05-06', '14', self.rid), ('2021-06-03', '14', self.rid)])
        args = ('2021-04-06','100.00', arr, '2021-04-20', '-12', str(self.course_id2), str(self.admin_id))
        query = self.generate_query("add_course_offering", args)
        res = self.check_fail_test(query, "Adding the offering with launch date after registration deadline should fail", RaiseException)

    
    def test_add_course_offering_registration_less_than_10_days_before_start_date_fail(self):
        # Add the course offering 1 time
        arr = self.make_session_array([('2021-04-30', '14', self.rid), ('2021-06-03', '14', self.rid)])
        args = ('2021-04-06','100.00', arr, '2021-04-27', '40', str(self.course_id1), str(self.admin_id))
        query = self.generate_query("add_course_offering", args)
        res = self.check_fail_test(query, "Adding the offering with launch date after registration deadline should fail", RaiseException)

    def test_add_course_offering_without_specialized_instructor_success(self):
        self._add_manager("Manager", ("AI",))
        self.course_id_ai = self._add_course("AI", "AI")
        sessions = self.make_session_array([('2021-05-07', '14', self.rid), ('2021-06-03', '14', self.rid)])
        args = ('2021-04-22','100.00', sessions, '2021-04-23', '40', str(self.course_id_ai), str(self.admin_id))
        query = self.generate_query("add_course_offering", args)
        self.check_fail_test(query, "Offering does not have enough instructors for sessions", RaiseException)