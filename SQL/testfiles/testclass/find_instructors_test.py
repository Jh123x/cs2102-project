import unittest
from unittest.case import expectedFailure
from . import BaseTest


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

    def _add_course(self, name:str, area:str):
        """Add a course to the table
            course title, course description, course area, and duration
        """
        args = (name, 'Description', area, '4')
        query = self.generate_query('add_course', args)
        res = self.execute_query(query)
        assert len(res) == 1, "Course is not added successfully"
        return res[0][0]

    def _add_course_offering(self):
        """Add course offering which will allocated sessions to the instructors"""
        pass


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
        # self.offering1 = self.

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

    @expectedFailure
    def test_find_free_instructor(self):
        """Find only free instructors from the free / not free ones"""
        # Make one instructor not free TODO


        # Check the number of free instructors
        args = (str(self.course_id), '2020-04-21', '9')
        query = self.generate_query('find_instructors', args)
        res = self.execute_query(query)
        assert len(res) == 3, "Not all the instructors are found correctly"

    @expectedFailure
    def test_find_no_free_instructor(self):
        """There are no free instructors"""
        # Make all the instructors not free TODO


        # Find the instructors
        args = (str(self.course_id), '2020-04-21', '9')
        query = self.generate_query('find_instructors', args)
        res = self.execute_query(query)
        assert len(res) == 0, "Not all the instructors are found correctly"

    @expectedFailure
    def test_find_one_instructor(self):
        """There is only 1 free instructors"""
        # Make all the other instructors not free TODO


        args = (str(self.course_id), '2020-04-21', '9')
        query = self.generate_query('find_instructors', args)
        res = self.execute_query(query)
        assert len(res) == 1, "Not all the instructors are found correctly"


    def test_find_all_instructors(self):
        """All instructors are free"""
        args = (str(self.course_id), '2020-04-21', '9')
        query = self.generate_query('find_instructors', args)
        res = self.execute_query(query)
        expected = [('(19,Instructor0)',), ('(20,Instructor1)',), ('(22,Instructor3)',), ('(23,Instructor4)',)]
        assert len(res) == 4, f"Not all the instructors are found correctly. {res}"
        assert res == expected, f"Expected: {expected}\nActual: {res}"
