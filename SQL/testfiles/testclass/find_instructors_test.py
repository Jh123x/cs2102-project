import unittest
from . import BaseTest
from unittest.case import expectedFailure
from psycopg2.errors import RaiseException


class FindInstructorsTest(BaseTest, unittest.TestCase):

    def _add_admin(self, name: str):
        """Add an admin into the table"""
        args = (name, 'address', '123456789', 'test@test.com',
                '2020-05-03', 'Admin', 'Full-time', '20.5')
        query = self.generate_query('add_employee', args)
        res = self.execute_query(query)
        assert len(res) > 0, "Admin not added successfully"
        return res[0][0]

    def _add_manager(self, name: str, areas: tuple):
        """Add a manager to the table with an area"""
        args = (name, 'address', '123456789', 'test@test.com', '2020-05-03',
                'Manager', 'Full-time', '20.5', self.process_arr_args(areas))
        query = self.generate_query('add_employee', args)
        res = self.execute_query(query)
        assert len(res) > 0, "Manager not added successfully"
        return res[0][0]

    def _add_instructor(self, name: str, time: str, areas: tuple):
        """Add an instructor to a table"""
        args = (name, 'address', '123456789', 'test@test.com', '2020-05-03',
                'Instructor', time, '20.5',  self.process_arr_args(areas))
        query = self.generate_query('add_employee', args)
        res = self.execute_query(query)
        assert len(res) > 0, "Instructor not added successfully"
        return res[0][0]

    def _add_course(self, name: str, area: str):
        """Add a course to the table
            course title, course description, course area, and duration
        """
        args = (name, 'Description', area, '4')
        query = self.generate_query('add_course', args)
        res = self.execute_query(query)
        assert len(res) == 1, "Course is not added successfully"
        return res[0][0]

    def make_not_free(self, inst_id: int) -> int:
        """Add course offering which will allocated sessions to the instructors
            returns the Session_id
        """

        # Add a course offering followed by a session
        query = f'SELECT course_area_name FROM Specializes WHERE instructor_id = {inst_id}'
        res = self.execute_query(query)[0][0]

        # Check cat for offering
        if 'Network' == res:
            offering = self.net_course_offering
        elif 'Database' == res:
            offering = self.db_course_offering
        else:
            raise ValueError(f'Wrong Category {res}')

        self.rid += 1
        query = f"INSERT INTO Sessions VALUES (1, '{self.session_date}', {self.session_time}, 12, {offering[5]}, '2025-05-21', {self.rid}, {inst_id})"
        self.execute_query(query)
        return 1

    def setUp(self) -> None:
        """Add Some personnels to the table to the table during setup"""

        # Add Manager
        self.manager_id = self._add_manager('Manager1', ("Database",))
        self.manager_id1 = self._add_manager('Manager2', ("Network",))

        # Add admin
        self.admin_id = self._add_admin('Admin1')

        # Add courses
        self.course_id = self._add_course('Database', 'Database')
        self.course_id1 = self._add_course('Network', 'Network')

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
        res = self.execute_query(query)

        query = f"INSERT INTO Rooms VALUES('2', 'Room2', '20')"
        res = self.execute_query(query)

        # Add session date and time
        self.session_date = '2025-06-10'
        self.session_time = '9'

        # Add Instructors
        self.instructor_ids = {}
        specialization = (
            ('Database',), ('Network', 'Database'), ("Network",))
        part_full_time = ('Part-Time', 'Full-time')
        for index in range(5):
            spec = specialization[index % len(specialization)]
            t = part_full_time[index % 2]
            self.instructor_ids[index] = (
                self._add_instructor(f'Instructor{index}', t, spec)
            )
        return super().setUp()

    def test_find_free_instructor(self):
        """Find only free instructors from the free / not free ones"""
        # Make one instructor not free TODO
        self.make_not_free(self.instructor_ids[0])

        # Check the number of free instructors
        args = (str(self.course_id), self.session_date, self.session_time)
        query = self.generate_query('find_instructors', args)
        res = self.execute_query(query)
        assert len(
            res) == 3, f"Not all the instructors are found correctly {res}"

        # Check if the output is correct
        expected = [('(28,Instructor1)',), ('(30,Instructor3)',),
                    ('(31,Instructor4)',)]
        assert res == expected

    def test_find_no_free_instructor(self):
        """There are no free instructors"""
        # Remove all the instructors except 1
        for id in tuple(self.instructor_ids.values())[1:]:
            q = f'''DELETE FROM Employees WHERE employee_id = {id};\
                DELETE FROM Specializes WHERE instructor_id = {id};\
                DELETE FROM Instructors WHERE instructor_id = {id};'''
            self.execute_query(q)

        # Make the instructor not free
        self.make_not_free(self.instructor_ids[0])

        # Find the instructors
        args = (str(self.course_id), self.session_date, self.session_time)
        query = self.generate_query('find_instructors', args)
        res = self.execute_query(query)
        assert len(
            res) == 0, f"Not all the instructors are found correctly {res}"
        assert res == [], f'The data struct is not correct'

    def test_find_one_instructor(self):
        """There is only 1 free instructors"""
        # Make all the other instructors not free TODO
        for id in tuple(self.instructor_ids.values())[2:]:
            q = f'''DELETE FROM Employees WHERE employee_id = {id};\
                DELETE FROM Specializes WHERE instructor_id = {id};\
                DELETE FROM Instructors WHERE instructor_id = {id};'''
            self.execute_query(q)

        # Make the first instructor not free
        self.make_not_free(self.instructor_ids[0])

        args = (str(self.course_id), self.session_date, self.session_time)
        query = self.generate_query('find_instructors', args)
        res = self.execute_query(query)
        assert len(res) == 1, "Not all the instructors are found correctly"

    def test_find_all_instructors(self):
        """All instructors are free"""
        args = (str(self.course_id), '2020-04-21', '9')
        query = self.generate_query('find_instructors', args)
        res = self.execute_query(query)
        expected = [('(19,Instructor0)',), ('(20,Instructor1)',),
                    ('(22,Instructor3)',), ('(23,Instructor4)',)]
        assert len(
            res) == 4, f"Not all the instructors are found correctly. {res}"
        assert res == expected, f"Expected: {expected}\nActual: {res}"
