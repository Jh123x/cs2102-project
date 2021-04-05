import unittest
from . import BaseTest
from psycopg2.errors import UniqueViolation

class HAddCourseOfferingTest(BaseTest, unittest.TestCase):
    pass
    # def _add_manager(self, name: str, areas: tuple):
    #     """Add a manager to the table with an area"""
    #     args = (
    #         name,
    #         "address",
    #         "123456789",
    #         "test@test.com",
    #         "2020-05-03",
    #         "Manager",
    #         "Full-time",
    #         "20.5",
    #         self.process_arr_args(areas),
    #     )
    #     query = self.generate_query("add_employee", args)
    #     res = self.execute_query(query)
    #     assert len(res) > 0, "Manager not added successfully"
    #     return res[0][0]
    # def _add_instructor(self, name: str, time: str, areas: tuple):
    #     """Add an instructor to a table"""
    #     args = (
    #         name,
    #         "address",
    #         "123456789",
    #         "test@test.com",
    #         "2020-05-03",
    #         "Instructor",
    #         time,
    #         "20.5",
    #         self.process_arr_args(areas),
    #     )
    #     query = self.generate_query("add_employee", args)
    #     res = self.execute_query(query)
    #     assert len(res) > 0, "Instructor not added successfully"
    #     return res[0][0]

    # def _add_course(self, name: str, area: str):
    #     """Add a course to the table
    #     course title, course description, course area, and duration
    #     """
    #     args = (name, "Description", area, "4")
    #     query = self.generate_query("add_course", args)
    #     res = self.execute_query(query)
    #     assert len(res) == 1, "Course is not added successfully"
    #     return res[0][0]
    # def _add_admin(self, name: str):
    #     """Add an admin into the table"""
    #     args = (
    #         name,
    #         "address",
    #         "123456789",
    #         "test@test.com",
    #         "2020-05-03",
    #         "Admin",
    #         "Full-time",
    #         "20.5",
    #     )
    #     query = self.generate_query("add_employee", args)
    #     res = self.execute_query(query)
    #     assert len(res) > 0, "Admin not added successfully"
    #     return res[0][0]

    # def setUp(self) -> None:
    #     # Add Manager
    #     self.manager_id = self._add_manager("Manager1", ("Database",))
    #     self.manager_id1 = self._add_manager("Manager2", ("Network",))

    #     # Add admin
    #     self.admin_id = self._add_admin("Admin1")

    #     # Add courses
    #     self.course_id = self._add_course("Database", "Database")
    #     self.course_id1 = self._add_course("Network", "Network")

    #     self.instructor_ids = {}
    #     specialization = (("Database",), ("Network", "Database"), ("Network",))
    #     part_full_time = ("Part-Time", "Full-time")
    #     for index in range(5):
    #         spec = specialization[index % len(specialization)]
    #         t = part_full_time[index % 2]
    #         self.instructor_ids[index] = self._add_instructor(
    #             f"Instructor{index}", t, spec
    #         )
    #     return super().setUp()

    # def test_add_course_offering(self):
    #     """Adding 2 different course offering should succeed"""

    #     # Add the course offering 1 time
    #     args = ('2021-04-05','100.00',"ARRAY[('2021-05-04','10','1'),('2021-06-04','10','1')]",'2021-04-20','20','20',str(self.course_id),str(self.admin_id))
    #     query = self.generate_query("add_course_offering", args)
    #     print(query)
    #     res = self.execute_query(query)
      
    #     assert len(res) > 0, "Course Offering 1 not added successfully"

    #     expected =[("(2021-04-05,100.00,2021-04-20,20,20,1,1,2021-05-04,2021-06-04)")]
    #     assert res == expected

        # args = ('2021-04-06','100.00','[(2021-05-06,10,1),(2021-06-06,10,1)]','2021-04-20','20','20','1','1')
        # query = self.generate_query("add_course_offering", args)
        # res = self.execute_query(query)
        # assert len(res) > 0, "Course Offering 1 not added successfully"
