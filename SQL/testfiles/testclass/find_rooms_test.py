import unittest
from . import BaseTest


class ZFindRoomsTest(BaseTest, unittest.TestCase):
    def setUp(self):
        """Additional charactors"""
        self.manager1 = self._add_manager("manager1", ("Network",))
        self.inst1 = self._add_instructor("inst1", "full-time", ("Network",))
        self.course1 = self._add_course("Networking", "Network")
        return super().setUp()

    def add_rooms(self):
        """Add 2 rooms into the db"""
        # Add rooms
        query = f"INSERT INTO Rooms VALUES('1', 'Room1', '20') RETURNING room_id"
        self.rid = self.execute_query(query)[0][0]

        query = f"INSERT INTO Rooms VALUES('2', 'Room2', '20') RETURNING room_id"
        self.rid1 = self.execute_query(query)[0][0]

    def make_not_free(self, rid: int, date: str, time: int, duration: int):
        """Add the rooms to the session"""
        admin_id = self._add_admin("admin1")
        q = f"INSERT INTO CourseOfferings VALUES('2020-04-04', 100, '2025-04-04', 20, 20, {self.course1}, {admin_id}, '2025-05-04', '2025-06-04')"
        self.execute_query(q)

        query = f"INSERT INTO Sessions VALUES(1, '{date}', {time}, {time+duration}, {self.course1}, '2020-04-04', {rid}, {self.inst1})"
        res = self.execute_query(query)
        return res

    def _add_admin(self, name: str) -> int:
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
        args = (name, "Description", area, "2")
        query = self.generate_query("add_course", args)
        res = self.execute_query(query)
        assert len(res) == 1, "Course is not added successfully"
        return res[0][0]

    def test_get_rooms_success(self):
        """Get all the rooms should return successfully"""

        # Add the rooms
        self.add_rooms()

        # Check for rooms
        args = ("2021-04-04", "9", "2")
        query = self.generate_query("find_rooms", args)
        res = self.execute_query(query)
        expected = [(1,), (2,)]
        assert res == expected, f"The number of room is incorrect {res}"

    def test_get_no_rooms_success(self):
        """Get nothing when there are no rooms"""
        args = ("2021-04-04", "9", "2")
        query = self.generate_query("find_rooms", args)
        res = self.execute_query(query)
        expected = []
        assert res == expected, f"The number of room is incorrect {res}"

    def test_get_no_rooms_when_taken(self):
        """Get nothing when the rooms are taken"""

        # Add the rooms
        self.add_rooms()

        # Vars
        date = "2025-05-05"
        time = 9
        duration = 2

        # Make one room not free
        self.make_not_free(self.rid, date, time, duration)

        # Check if it returns 1 room
        args = (date, str(time), str(duration))
        q = self.generate_query("find_rooms", args)
        res = self.execute_query(q)
        assert len(res) == 1, f"Incorrect number of rooms found: {res}"
