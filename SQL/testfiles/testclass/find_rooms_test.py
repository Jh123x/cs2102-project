import unittest
from . import BaseTest


class ZFindRoomsTest(BaseTest, unittest.TestCase):
    def setUp(self):
        """Add some of the rooms"""
        query = f"INSERT INTO Rooms VALUES('1', 'Room1', '20')"
        self.rid = self.execute_query(query)

        query = f"INSERT INTO Rooms VALUES('2', 'Room2', '20')"
        self.rid1 = self.execute_query(query)
        return super().setUp()

    def test_get_rooms_success(self):
        """Get all the rooms should return successfully"""
        args = ("2021-04-04", "9", "2")
        query = self.generate_query("find_rooms", args)
        res = self.execute_query(query)
        expected = [(1,), (2,)]
        assert res == expected, f"The number of room is incorrect {res}"