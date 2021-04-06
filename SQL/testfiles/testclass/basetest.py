def parse_args(arg: str):
    if '::' in arg or '[' in arg:
        return arg
    return f"'{arg}'"


class BaseTest(object):
    DB = None
    CURSOR = None
    ERR_MSG = "Expected: %s\nActual: %s"

    def tearDown(self) -> None:
        """Tear down after each test case"""
        self.DB.rollback()

    def _parse_args(self, args: tuple):
        """Parse the arguments into a string"""
        return ", ".join(map(parse_args, args))

    def process_arr_args(self, arr_args: tuple):
        """Transform the args into sql array"""
        res = map(lambda x: f"'{x}'", arr_args)
        return f'ARRAY[{", ".join(res)}]'

    def generate_query(self, function: str, args: tuple) -> None:
        """Generate query based on arguments"""
        return f"""SELECT {function}({self._parse_args(args)})"""

    def execute_query(self, query: str) -> list:
        """Execute query and return the result at the cursor"""
        self.CURSOR.execute(query)
        try:
            res = self.fetch_all()
        except Exception:
            return None
        return res

    def fetch_all(self):
        """Get the result from the previous query"""
        return self.CURSOR.fetchall()

    def value_test(self, query:str, expected):
        """Test value"""
        self.execute_query(query)
        actual = self.fetch_all()
        for v, e in zip(actual, expected):
            assert v == e, self.ERR_MSG % (e, v)

    def check_fail_test(self, query: str, msg: str, expected_error: tuple) -> None:
        """Check test cases which are suppose to fail"""
        try:
            self.execute_query(query)
        except expected_error:
            pass
        else:
            raise AssertionError(msg)

    def _add_person(self, role: str, course_areas: list = 'ARRAY[]::TEXT[]') -> int:
        """Add a manager into the table"""
        args = ["John", "address", '987654321', 'test@test.com',
                '2020-05-03', role, "full-time", '10.5', str(course_areas)]
        query = self.generate_query("add_employee", tuple(args))
        return self.execute_query(query)

    def _add_course(self, category:str, duration:int) -> int:
        """Adds a course into the table
            returns the course id
        """
        args = ("Database Systems", "Test description", category, str(duration))
        q = self.generate_query('add_course', args)
        return self.generate_query(q)

    def make_session_array(self, rows:list):
        def wrapper(tup: tuple):
            acc = ['row(']
            acc.append(", ".join(map(lambda ele: f"'{ele}'", tup)))
            acc.append(')::session_information')
            return ''.join(acc)
        res = f"ARRAY[{', '.join(map(wrapper, rows))}]"
        return res

    def _add_course_offering(self, launch_date:str, fees:int, session_array:list, reg_deadline:str, target_num:int, course_id:int, admin_id:int):
        """Add a course offering"""
        args = (launch_date, str(fees), self.make_session_array(session_array), reg_deadline, str(target_num), str(course_id), str(admin_id))
        q = self.generate_query('add_course_offering', args)
        res = self.execute_query(q)
        return res

    def _add_room(self, room_id:int, room_name:str, room_capacity:int):
        query = f"INSERT INTO Rooms VALUES('{room_id}', '{room_name}', '{room_capacity}') RETURNING room_id"
        return self.execute_query(query)[0][0]

