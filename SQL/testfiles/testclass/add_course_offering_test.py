import unittest
from . import BaseTest
from psycopg2.errors import UniqueViolation

class HAddCourseOfferingTest(BaseTest, unittest.TestCase):
    pass
#     def setUp(self) -> None:
#         # Add a course
#         args =('sleep','sleep','Rest','2')
#         query = self.generate_query("add_course", args)
#         res = self.execute_query(query)
#         assert len(res) > 0, "Course not added successfully"

#         # Add Instructor 
#         """Add an instructor to a table"""
#         args = (
#             "help",
#             "address",
#             "123456789",
#             "test@test.com",
#             "2020-05-03",
#             "Instructor",
#             time,
#             "20.5",
#             self.process_arr_args(areas),
#         )
#         query = self.generate_query("add_employee", args)
#         res = self.execute_query(query)
#         assert len(res) > 0, "Instructor not added successfully"

#         # Add Administrator
#          args = (
#             name,
#             "address",
#             "123456789",
#             "test@test.com",
#             "2020-05-03",
#             "Admin",
#             "Full-time",
#             "20.5",
#         )
#         query = self.generate_query("add_employee", args)
#         res = self.execute_query(query)
#         assert len(res) > 0, "Admin not added successfully"



#     def test_add_course_offering(self):
#         """Adding 2 different course offering should succeed"""

#         # Add the course offering 1 time
#         args = ('2021-04-05','100.00','[(2021-05-04,10,1),(2021-06-04,10,1)]','2021-04-20','20','20','1','1')
