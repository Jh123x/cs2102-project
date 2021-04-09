import unittest
from . import BaseTest
from psycopg2.errors import RaiseException


class JPopularCoursesTest(BaseTest, unittest.TestCase):
    def setUp(self) -> None:
        """Set up the sessions to be modified"""
        # Add a manager
        self.manager_id = self._add_person('Manager', "Array['Database']")
        self.manager_id1 = self._add_person('Manager', "Array['Network']")

        # Add an instructor
        self.instructor_id1 = self._add_person('Instructor', "Array['Database','Network']")
        self.instructor_id2 = self._add_person('Instructor', "Array['Database']")
        self.instructor_id3 = self._add_person('Instructor', "Array['Database','Network']")
        self.instructor_id4 = self._add_person('Instructor', "Array['Database']")

        # Add an admin
        self.admin_id = self._add_person('Admin')

        # Add a course
        self.course_id1 = self._add_course('Database', 1)
        self.course_id2 = self._add_course('Network', 1, 'Networks')
        self.course_id3 = self._add_course('Database',1,'PSQL')

        # Add a room
        self.room_id = self._add_room(1, 'Test room 1', 20)
        self.room_id2 = self._add_room(2, 'Test room 2', 20)
        self.room_id3 = self._add_room(3, 'Test room 3', 20)
        self.room_id4 = self._add_room(4, 'Test room 4', 20)
        self.room_id5 = self._add_room(5, 'Test room 5', 20)

        # Add a customer
        self.customer_id1 = self._add_customer('Test1', "test", 987654321, 'test1@test.com', '1234123412341234', '123', '2025-05-31')
        self.customer_id2 = self._add_customer('Test2', "test", 976543210, 'test2@test.com', '1234123512341234', '123', '2025-05-31')
        self.customer_id3 = self._add_customer('Test3', "test", 965432101, 'test3@test.com', '1234123412351234', '123', '2025-05-31')
        self.customer_id4 = self._add_customer('Test4', "test", 954321012, 'test4@test.com', '1234123412341235', '123', '2025-05-31')
        self.customer_id5 = self._add_customer('Test5', "test", 943210123, 'test5@test.com', '1235123412341234', '123', '2025-05-31')
        
        # Add 5 course offering
        self.course_offering1 = self._add_course_offering('2021-01-21', 10, [('2021-06-21', 9, self.room_id)], '2021-05-31', 20, self.course_id1, self.admin_id)
        self.course_offering2 = self._add_course_offering('2021-02-21', 10, [('2021-06-22', 10, self.room_id2)], '2021-05-31', 20, self.course_id2, self.admin_id)
        self.course_offering3 = self._add_course_offering('2021-03-21', 10, [('2021-06-21', 14, self.room_id3)], '2021-05-31', 20, self.course_id3, self.admin_id)
        self.course_offering4 = self._add_course_offering('2021-04-21', 10, [('2021-06-22', 15, self.room_id4)], '2021-05-31', 20, self.course_id1, self.admin_id)
        self.course_offering5 = self._add_course_offering('2021-05-21', 10, [('2021-06-23', 16, self.room_id5)], '2021-05-31', 20, self.course_id2, self.admin_id)

    def test_no_popular_package(self):
        """Test for popular courses without registrations"""
        args = ()
        q = self.generate_query("popular_courses", args)
        res = self.execute_query(q)

        expected =[]
        assert res == expected, f'\nOutput:   {res}\nExpected: {expected}'

    def test_0_popular_package(self):
        """Test for popular courses with registrations"""
        # 1 customer register for the first offering
        args = ('2021-01-21',  str(self.course_id1), '1',
                str(self.customer_id1), 'Credit Card')
        q = self.generate_query('register_session', args)
        self.execute_query(q)

        # 1 customer register for the second offering
        args = ('2021-02-21', str(self.course_id2), '1',
                str(self.customer_id2), 'Credit Card')
        q = self.generate_query('register_session', args)
        self.execute_query(q)

        # 1 customer register for the third offering
        args = ('2021-03-21', str(self.course_id3), '1',
                str(self.customer_id3), 'Credit Card')
        q = self.generate_query('register_session', args)
        self.execute_query(q)

        args =()
        q = self.generate_query("popular_courses", args)
        res = self.execute_query(q)

        expected =[]
        assert res == expected, f'\nOutput:   {res}\nExpected: {expected}'

    def test_1_popular_package(self):
        """Test for popular courses with registrations"""
        # 2 customer register for the first offering
        args = ('2021-01-21',  str(self.course_id1), '1',
                str(self.customer_id1), 'Credit Card')
        q = self.generate_query('register_session', args)
        self.execute_query(q)
        args = ('2021-04-21',  str(self.course_id1), '1',
                str(self.customer_id2), 'Credit Card')
        q = self.generate_query('register_session', args)
        self.execute_query(q)

        # 3 customer register for the second offering
        args = ('2021-02-21', str(self.course_id2), '1',
                str(self.customer_id3), 'Credit Card')
        q = self.generate_query('register_session', args)
        self.execute_query(q)

        args = ('2021-05-21', str(self.course_id2), '1',
                str(self.customer_id4), 'Credit Card')
        q = self.generate_query('register_session', args)
        self.execute_query(q)

        args = ('2021-05-21', str(self.course_id2), '1',
                str(self.customer_id5), 'Credit Card')
        q = self.generate_query('register_session', args)
        self.execute_query(q)

        args =()
        q = self.generate_query("popular_courses", args)
        res = self.execute_query(q)

        expected =[('(68,Networks,Network,2,2)',)]
        assert res == expected, f'\nOutput:   {res}\nExpected: {expected}'

    def setup_empty_courses(self):
        """Create empty courses that no one joins"""
        # Add manager to add the course area
        self.manager = self._add_person('Manager', 'ARRAY[\'Operation System\']')

        # Add the empty courses
        self.empty_course1 = self._add_course('Operation System', 1, 'Operation System')

    def test_empty_courses_no_return(self):
        """Test popular courses with courses that has 0 offerings"""
        # Create courses with no offerings
        self.setup_empty_courses()

        # Execute the command
        q = self.generate_query('popular_courses', ())
        res = self.execute_query(q)
        assert len(res) == 0, 'Courses without offerings should not be added'