import unittest
from . import BaseTest
from datetime import datetime
from psycopg2.errors import RaiseException, ForeignKeyViolation, CheckViolation


class JAddSessionTest(BaseTest, unittest.TestCase):
    def setUp(self):
        """Add an additional attribute to add the date today"""
        # Add Manager
        self.manager_id = self._add_manager("Manager1", ("Database",))
        self.manager_id1 = self._add_manager("Manager2", ("Network",))

        # Add admin
        self.admin_id = self._add_admin("Admin1")

        # Add courses
        self.course_id = self._add_course("Database", "Database")
        self.course_id1 = self._add_course("Network", "Network")

        # Add course_offering
        self.db_course_offering = self.execute_query(
            f"INSERT INTO CourseOfferings VALUES('2025-05-21', '10.5', '2025-05-25', '20', '20', {self.course_id}, {self.admin_id}, '2025-06-04', '2025-07-31') RETURNING *"
        )[0]
        self.net_course_offering = self.execute_query(
            f"INSERT INTO CourseOfferings VALUES('2025-05-21', '10.5', '2025-05-25', '20', '20', {self.course_id1}, {self.admin_id}, '2025-06-04', '2025-07-31') RETURNING *"
        )[0]

        # Add 2 room
  
        query = f"INSERT INTO Rooms VALUES('1', 'Room1', '20')"
        self.execute_query(query)
        
        query = f"INSERT INTO Rooms VALUES('2', 'Room2', '20')"
        self.execute_query(query)

        # Add session date and time
        self.session_date = "2025-06-10"
        self.session_time = "9"

        # Add Instructors
        self.instructor_ids = {}
        specialization = (("Database",), ("Network", "Database"), ("Network",))
        part_full_time = ("Part-Time", "Full-time")
        for index in range(5):
            spec = specialization[index % len(specialization)]
            t = part_full_time[index % 2]
            self.instructor_ids[index] = self._add_instructor(
                f"Instructor{index}", t, spec
            )

        # Sanity Check
        query = "SELECT * FROM Employees"
        res = self.execute_query(query)
        assert len(res) == 8, f"Incorrect number of employees {res}"

        return super().setUp()

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
        args = (name, "Description", area, "1")
        query = self.generate_query("add_course", args)
        res = self.execute_query(query)
        assert len(res) == 1, "Course is not added successfully"
        return res[0][0]

    def test_add_session(self):
        """Adding 2 different session should succeed"""
        args = (str(self.course_id), '2025-05-21','1', '2025-06-04','10', str(self.instructor_ids[0]),'1')
        query = self.generate_query("add_session",args)
        res = self.execute_query(query)
         
        assert len(res) == 1, "Session is not added successfully"

        args = (str(self.course_id), '2025-05-21','2', '2025-07-31','10', str(self.instructor_ids[0]), '1')
        query = self.generate_query("add_session",args)
        res = self.execute_query(query)

        assert len(res) == 1, "Session is not added successfully"
    
    def test_add_session_room_occupied_fail(self):
        """Adding a session with room occupied should fail"""
        args = (str(self.course_id), '2025-05-21','1', '2025-06-04','10', str(self.instructor_ids[0]), '1')
        query = self.generate_query("add_session",args)
        res = self.execute_query(query)
        assert len(res) == 1, "Session is not added successfully" 

        args = (str(self.course_id1), '2025-05-21','1', '2025-06-04','10', str(self.instructor_ids[1]), '1')
        query = self.generate_query("add_session",args)
        res = self.check_fail_test(query,"Session room is occupied", RaiseException)

    def test_add_session_instructor_occupied_fail(self):

        args = (str(self.course_id), '2025-05-21','1', '2025-06-04','10', str(self.instructor_ids[0]), '1')
        query = self.generate_query("add_session",args)
        res = self.execute_query(query)
        assert len(res) == 1, "Session is not added successfully" 

        args = (str(self.course_id1), '2025-05-21','1', '2025-06-04','10', str(self.instructor_ids[0]), '2')
        query = self.generate_query("add_session",args)
        res = self.check_fail_test(query,"Session instructor is unavailable", RaiseException)

    def test_add_session_id_duplicate_fail(self):

        args = (str(self.course_id), '2025-05-21','1', '2025-06-04','10', str(self.instructor_ids[0]), '1')
        query = self.generate_query("add_session",args)
        res = self.execute_query(query)
        assert len(res) == 1, "Session is not added successfully" 

        args = (str(self.course_id), '2025-05-21','1', '2025-07-31','10', str(self.instructor_ids[0]), '2')
        query = self.generate_query("add_session",args)
        res = self.check_fail_test(query,"Session ID already exist", RaiseException)
    