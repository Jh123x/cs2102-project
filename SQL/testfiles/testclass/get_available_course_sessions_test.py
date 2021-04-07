import unittest
from . import BaseTest
from unittest import expectedFailure


class ZGetAvailableCourseSessionsTest(BaseTest, unittest.TestCase):
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
        args = (name, "Description", area, "2")
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
        query = f"INSERT INTO Rooms VALUES('1', 'Room1', '1') RETURNING room_id"
        self.rid = self.execute_query(query)[0][0]

        query = f"INSERT INTO Rooms VALUES('2', 'Room2', '1') RETURNING room_id"
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

         # Add a customer
        self.customer_id = self._add_customer('Test1', "test", 987654321, 'test@test.com', '1234123412341234', '123', '2025-05-31')

        return super().setUp()

    def test_no_sessions_avail(self):
        """Return nothing when there are no sessions"""
        # Using information that is not found
        args = ("2020-04-21", "1")

        # Execute the function
        q = self.generate_query("get_available_course_sessions", args)
        res = self.execute_query(q)

        # Check that it is empty
        assert res == [], f"There are no sessions {res}"
    
    def test_all_sessions_avail(self):
        """Return 2 when there are 2 sessions"""
        # Create 2 sessions 
        arr = self.make_session_array([('2021-05-06', '14', str(self.rid)),('2021-05-06', '10', str(self.rid))])
        args = ('2021-04-06','100.00', arr, '2021-04-20', '2', str(self.course_id), str(self.admin_id))
        query = self.generate_query("add_course_offering", args)
        res = self.execute_query(query)


        args = ("2021-04-06", str(self.course_id))
        # Execute the function
        q = self.generate_query("get_available_course_sessions", args)
        res = self.execute_query(q)

        # Check that it is has 2 session available
        assert (
            len(res) == 2
        ), "There should be 2 course sessions available"
        expected =[('(2021-05-06,10,Instructor0,1)',), ('(2021-05-06,14,Instructor0,1)',)]
        assert res == expected, f'\nOutput:   {res}\nExpected: {expected}'
  
    def test_half_sessions_avail(self):
        """Return 2 when there are 2 sessions"""
        # Create 2 sessions 
        arr = self.make_session_array([('2021-05-06', '14', str(self.rid)),('2021-05-06', '10', str(self.rid))])
        args = ('2021-04-06','100.00', arr, '2021-04-20', '2', str(self.course_id), str(self.admin_id))
        query = self.generate_query("add_course_offering", args)
        res = self.execute_query(query)

        # Register one student
        args = ('2021-04-06', str(self.course_id), '1', str(self.customer_id), 'Credit Card')
        q = self.generate_query('register_session', args)
        self.execute_query(q)


        args = ("2021-04-06", str(self.course_id))
        # Execute the function
        q = self.generate_query("get_available_course_sessions", args)
        res = self.execute_query(q)

        # Check that it is empty
        assert (
            len(res) == 1
        ), "There should be 1 course session available"
        expected =[('(2021-05-06,10,Instructor0,1)',)]
        assert res == expected, f'\nOutput:   {res}\nExpected: {expected}'