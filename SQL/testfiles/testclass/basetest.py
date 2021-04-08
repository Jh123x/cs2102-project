import datetime


def parse_args(arg: str):
    if "::" in arg or "[" in arg:
        return arg
    return f"'{arg}'"


class BaseTest(object):
    DB = None
    CURSOR = None
    ERR_MSG = "Expected: %s\nActual: %s"
    TODAY = datetime.datetime.now().date()

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

    def value_test(self, query: str, expected):
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

    def _add_person(
        self,
        role: str,
        course_areas: str = "ARRAY[]::TEXT[]",
        salary: int = 10.5,
        join_date: str = "2020-05-03",
    ) -> int:
        """Add a person into the table based on role"""
        args = [
            "John",
            "address",
            "987654321",
            "test@test.com",
            join_date,
            role,
            "full-time",
            str(salary),
            str(course_areas),
        ]
        query = self.generate_query("add_employee", tuple(args))
        return self.execute_query(query)[0][0]

    def _add_part_time_instr(
        self, course_areas: str = "ARRAY[]::TEXT[]", salary: int = 1
    ):
        """Add a part time instructor into the table"""
        args = [
            "John",
            "address",
            "987654321",
            "test@test.com",
            "2020-05-03",
            "Instructor",
            "part-time",
            str(salary),
            str(course_areas),
        ]
        query = self.generate_query("add_employee", tuple(args))
        return self.execute_query(query)[0][0]

    def _add_course(
        self, category: str, duration: int, name: str = "Database Systems"
    ) -> int:
        """Adds a course into the table
        returns the course id
        """
        args = (name, "Test description", category, str(duration))
        q = self.generate_query("add_course", args)
        return self.execute_query(q)[0][0]

    def make_session_array(self, rows: list):
        """Convert the list to a session_information class"""

        def wrapper(tup: tuple):
            acc = ["row("]
            acc.append(", ".join(map(lambda ele: f"'{ele}'", tup)))
            acc.append(")::session_information")
            return "".join(acc)

        res = f"ARRAY[{', '.join(map(wrapper, rows))}]"
        return res

    def _add_course_offering(
        self,
        launch_date: str,
        fees: int,
        session_array: list,
        reg_deadline: str,
        target_num: int,
        course_id: int,
        admin_id: int,
    ):
        """Add a course offering"""
        args = (
            launch_date,
            str(fees),
            self.make_session_array(session_array),
            reg_deadline,
            str(target_num),
            str(course_id),
            str(admin_id),
        )
        q = self.generate_query("add_course_offering", args)
        res = self.execute_query(q)
        return res

    def _add_room(self, room_id: int, room_name: str, room_capacity: int):
        """Adds a room to the db"""
        query = f"INSERT INTO Rooms VALUES('{room_id}', '{room_name}', '{room_capacity}') RETURNING room_id"
        return self.execute_query(query)[0][0]

    def _add_customer(
        self,
        name: str,
        addr: str,
        phone: int,
        email: str,
        credit_card_no: str,
        cvv: str,
        card_expiry_date: str,
    ) -> int:
        """Adds a customer to the db
        returns the id of the customer
        """
        args = (name, addr, str(phone), email, credit_card_no, cvv, card_expiry_date)
        query = self.generate_query("add_customer", args)
        return self.execute_query(query)[0][0]

    def _add_course_package(
        self,
        pkg_name: str,
        no_redemptions: int,
        offer_start_date: str,
        offer_end_date: str,
        cost: int,
    ):
        """Add a course package"""
        args = (
            pkg_name,
            str(no_redemptions),
            offer_start_date,
            offer_end_date,
            str(cost),
        )
        query = self.generate_query("add_course_package", args)
        return self.execute_query(query)[0][0]

    def _buy_package(self, customer_id: int, package_id: int) -> int:
        """Customer buys package"""
        q = self.generate_query(
            "buy_course_package", (str(customer_id), str(package_id))
        )
        return self.execute_query(q)

    def _register_credit_card(self, date: str, course_id: int, session_id: int, customer_id: int):
        args = (date, str(course_id), str(session_id), str(customer_id), 'Credit Card')
        q = self.generate_query('register_session', args)
        self.execute_query(q)

    def _register_redeems(self, date: str, course_id: int, session_id: int, customer_id: int):
        args = (date, str(course_id), str(session_id), str(customer_id), 'Redemption')
        q = self.generate_query('register_session', args)
        self.execute_query(q)

    def _cancel_registration(self, customer_id: int, course_id: int):
        args = (str(customer_id), str(course_id), '2021-01-21')
        q = self.generate_query('cancel_registration', args)
        self.execute_query(q) #No return

    def time_cmp(self, time1: datetime.datetime, time2: datetime.datetime) -> bool:
        """Compare timestamps to see if they are close enough"""
        return time1 - time2 < datetime.timedelta(seconds=0.5)
