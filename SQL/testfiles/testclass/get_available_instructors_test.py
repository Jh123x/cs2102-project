import unittest
import datetime
from unittest.case import expectedFailure
from . import BaseTest


class IGetAvailableInstrutors(BaseTest, unittest.TestCase):
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
        self.rid = 0
        query = f"INSERT INTO Rooms VALUES('1', 'Room1', '20')"
        self.execute_query(query)

        query = f"INSERT INTO Rooms VALUES('2', 'Room2', '20')"
        self.execute_query(query)

        query = f"INSERT INTO Rooms VALUES('3', 'Room3', '20')"
        self.execute_query(query)

        query = f"INSERT INTO Rooms VALUES('4', 'Room4', '20')"
        self.execute_query(query)

        query = f"INSERT INTO Rooms VALUES('5', 'Room5', '20')"
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

    def make_not_free(self, inst_id: int, sess_id:int, sess_time:int) -> int:
        """Add course offering which will allocated sessions to the instructors
        returns the Session_id
        """

        # Add a course offering followed by a session
        query = (
            f"SELECT course_area_name FROM Specializes WHERE instructor_id = {inst_id}"
        )
        res = self.execute_query(query)[0][0]

        # Check cat for offering
        if "Network" == res:
            offering = self.net_course_offering
        elif "Database" == res:
            offering = self.db_course_offering
        else:
            raise ValueError(f"Wrong Category {res}")

        self.rid += 1

        query = f"INSERT INTO Sessions VALUES ('{sess_id}', '{self.session_date}', {sess_time}, {sess_time +1}, '{offering[5]}', '{offering[0]}', {self.rid}, {inst_id})"
        self.execute_query(query)
        return 1

    def test_get_available_instructors_success(self) -> None:
        """Test get available instructructors if they can get all the instructors"""
        date = "2021-03-04"
        args = (str(self.course_id), date, "2021-03-04")
        query = self.generate_query("get_available_instructors", args)
        res = self.execute_query(query)
        assert len(res) == 4, f"The number of instructors is not correct {res}"

    def test_get_none_available_instructor_success(self) -> None:
        """Get behavior when there is only 1 available instructor"""
        args = (str(self.course_id1), "2020-04-04", "2020-04-06")
        query = self.generate_query("get_available_instructors", args)
        res = self.execute_query(query)
        assert len(res) == 0, f"Number of instructors is incorrect {res}"


    def test_get_one_available_instructors_success(self) -> None:
        """Get available instructors when there is only 1 that is available"""
        starttime = (9,10,14,15,16)
        for index in range(5):
           self.make_not_free(self.instructor_ids[index],index+1,starttime[index])

        args = (str(self.course_id),  "2025-06-10", "2025-06-10")
        query = self.generate_query("get_available_instructors", args)
        res = self.execute_query(query)

        expected = [('({},Instructor0,1,2025-06-10,"{{11,14,15,16,17}}")'.format(self.instructor_ids[0]),),
                    ('({},Instructor1,1,2025-06-10,"{{14,15,16,17}}")'.format(self.instructor_ids[1]),),
                    ('({},Instructor3,1,2025-06-10,"{{9,10,11,17}}")'.format(self.instructor_ids[3]),),
                    ('({},Instructor4,1,2025-06-10,"{{9,10,11,14}}")'.format(self.instructor_ids[4]),)]
        assert res == expected, f'\nOutput:   {res}\nExpected: {expected}'
