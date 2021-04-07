import unittest
from . import BaseTest
from unittest import expectedFailure
from psycopg2.errors import RaiseException


class ZGetAvailableCourseOfferings(BaseTest, unittest.TestCase):
    
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

    def make_session_array(self, rows: list):
        def wrapper(tup: tuple):
            acc = ['row(']
            acc.append(", ".join(map(lambda ele: f"'{ele}'", tup)))
            acc.append(')::session_information')
            return ''.join(acc)
        res = f"ARRAY[{', '.join(map(wrapper, rows))}]"
        return res

    def test_no_course_offering_available(self):
        """No offering available should return empty list"""
        q = self.generate_query("get_available_course_offerings", ())
        res = self.execute_query(q)

        assert len(
            res) == 0, "No course offering available should return empty table"
    
    def test_course_offering_avail(self):
        """All course offering are available"""
        # Add 1 course offering to the table
        arr = self.make_session_array([('2021-07-05', '14', self.rid1), ('2021-08-06', '14', self.rid1)])
        args = ('2021-03-05','100.00', arr, '2021-06-20', '40', str(self.course_id), str(self.admin_id))
        q = self.generate_query('add_course_offering', args)
        res = self.execute_query(q)

        # Get the course offering from the table
        q = self.generate_query("get_available_course_offerings", ())
        res = self.execute_query(q)

        # Check if there is exactly 1 course offering
        assert len(res) == 1, f"Should return 1 but it returned {res}"

    
    def test_course_offering_half_avail(self):
        """Only some of the course offering are avail"""
        # Add 2 course offerings to the table
        arr = self.make_session_array([('2021-07-05', '14', self.rid), ('2021-08-06', '14', self.rid)])
        args = ('2021-03-05','100.00', arr, '2021-06-20', '40', str(self.course_id2), str(self.admin_id))
        q = self.generate_query('add_course_offering', args)
        res = self.execute_query(q)

        query = f"INSERT INTO CourseOfferings VALUES('2021-03-14'::DATE,100.00,'2021-04-01'::DATE,20,20,"+ str(self.course_id)+", "+ str(self.admin_id)+",'2021-05-14'::DATE,'2021-06-14'::DATE)"
        self.execute_query(query)
        query = f"INSERT INTO Sessions VALUES(1,'2021-07-06'::DATE,14,18,"+ str(self.course_id)+", '2021-03-14'::DATE,"+ str(self.rid)+","+ str(self.instructor_ids[1])+")"
        self.execute_query(query)

        # Get the course offering from the table
        q = self.generate_query("get_available_course_offerings", ())
        res = self.execute_query(q)

        # Check if there is exactly 1 course offering
        assert len(res) == 1, f"Should return 1 but it returned {res}"
