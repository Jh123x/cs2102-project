#!/usr/bin/python3
import os
import csv
import json
import logging
import datetime
import psycopg2
import unittest
import configparser
from getpass import getpass
from testfiles.testclass.basetest import BaseTest
from testfiles.testclass.add_employee_test import AddEmployeeTest


# Define constants
SETTINGS_DIRECTORY = "settings.cfg"

# Make the logger
logger = logging.Logger("Logs")
logger.setLevel(logging.NOTSET)

FILES_TEST_MAP = [
    ('Employee_Test.csv', "Employees"),
    ('Customers_Test.csv', 'Customers'),
    ('Full_Time_Employee_Test.csv', 'FullTimeEmployees'),
    ('Part_Time_Employee_Test.csv', 'PartTimeEmployees'),
    ('Instructor_Test.csv', 'Instructors'),
    ('Admin_Test.csv', 'Administrators'),
    ('Manager_Test.csv', 'Managers'),
    ('Full_Time_Instructors_Test.csv', 'FullTimeInstructors'),
    ('Part_Time_Instructors_Test.csv', 'PartTimeInstructors'),
    ('Credit_Card_Test.csv', 'CreditCards'),
    ('Owns_Test.csv', 'Owns'),
    ('Course_Area_Test.csv', 'CourseAreas'),
    ('Course_Test.csv', 'Courses'),
    ('Course_Offering_Test.csv', 'CourseOfferings'),
    ('Course_Package_Test.csv', 'CoursePackages'),
    ('Specializes_Test.csv', 'Specializes'),
    ('Room_Test.csv', 'Rooms'),
    ('Session_Test.csv', 'Sessions'),
    ('Buys_Test.csv', 'Buys'),
    ('Redeem_Test.csv', 'Redeems'),
    ('Registers_Test.csv', 'Registers'),
    ('Cancels_Test.csv', 'Cancels'),
    ('Payslips_Test.csv', 'PaySlips'),
]


# DB functions
def connect_db(host: str, port: int, user: str, password: str, dbname: str):
    """Connect to the database and return the database object"""
    conn = psycopg2.connect(
        database=dbname, host=host, port=port, user=user, password=password
    )
    return conn


# General functions

def _get_data(csv_path: str, csv_obj):
    """Main logic for get_data"""
    data = []
    with open(csv_path) as file:
        reader = csv_obj(file)
        for row in reader:
            data.append(row)
    return tuple(data[0].keys()), data


def get_data(csv_path: str) -> tuple:
    """Get data from csv"""
    return _get_data(csv_path, csv.DictReader)


def get_function_data(csv_path: str) -> tuple:
    return _get_data(csv_path, csv.reader)


def check_date(date_string: str) -> datetime.datetime:
    """Check if the format is correct"""
    try:
        return datetime.datetime.strptime(date_string, r"%d/%m/%Y")
    except Exception as e:
        return False


def order_correctly(header, data) -> str:
    """Fix the ordering of the dict"""
    head2 = []
    acc = []
    for head in header:
        d = data[head]
        c = check_date(d)
        if d.isdigit() and 'credit' not in head:
            d = d
        elif c:
            d = f"'{c.strftime(r'%Y-%m-%d')}'"
        elif '_num_work_' in head and not d.strip():
            continue
        else:
            d = f"'{d}'"
        acc.append(d)
        head2.append(head)
    return head2, f"""({', '.join(acc)})"""


def generate_query(table_name: str, header: tuple, data: dict) -> str:
    """Generate the query based on header and data"""
    header, values = order_correctly(header, data)
    return f"INSERT INTO {table_name}({', '.join(header)}) VALUES {values};"


def generate_function_query(function: str, args: tuple) -> str:
    """Generate a function for the query"""
    return f"SELECT {function}({', '.join(args)})"


def get_query(path: str) -> str:
    """Get the query from the file"""
    with open(path) as file:
        res = file.read()
    return res


def get_files(directory: str) -> list:
    """Get the files in the folder except files with drop_all_"""
    if not os.path.isdir(directory):
        raise NotADirectoryError(f"{directory} is not a directory")
    return list(filter(lambda x: "drop_all" not in x.lower(),  [x[-1] for x in os.walk(directory)][0]))


def execute_query(cursor, query_paths: list) -> None:
    """Read query from list of files and execute them"""
    for path in query_paths:
        query = get_query(path)
        if query.strip() == "":
            logging.info(f"File {path} is empty, skipping")
            continue
        try:
            cursor.execute(query)
        except Exception as e:
            raise ValueError(f"Query: at {path} has error: {e}")


def map_with_dir(dirname: str, filenames: list) -> list:
    """Map the dirname (str) to the filenames (list of string)"""
    return list(map(lambda x: os.path.join(dirname, x), filenames))


# Schema functions
def drop_schema(cursor, schema_dir: str) -> None:
    """Drop the schema"""
    logger.debug("Dropping Schema")
    execute_query(cursor, map_with_dir(schema_dir, ["drop_all_tables.sql"]))
    logger.debug("Dropped Schema")


def setup_schema(cursor, schema_dir: str) -> None:
    """Run the schema files"""
    logger.debug("Setting up Schema")
    filenames = [
        "Employees",
        "Customers",
        "Rooms",
        "CourseAreas",
        "Courses",
        "CourseOfferings",
        "Sessions",
        "CoursePackages",
        "OwnsBuysRedeemsRegisters",
        "PaySlips",
        "Specializes",
    ]

    # Run the query
    execute_query(cursor, map_with_dir(
        schema_dir, map(lambda x: f"{x}.sql", filenames)))
    logger.debug("Schema added")


# Trigger functions
def drop_triggers(cursor, trigger_dir: str) -> None:
    """Drop all the previous triggers"""
    logger.debug("Dropping triggers")
    execute_query(cursor, map_with_dir(trigger_dir, ["drop_all_triggers.sql"]))
    logger.debug("Triggers dropped")


def setup_triggers(cursor, trigger_dir: str) -> None:
    """Set up the triggers"""
    logger.debug("Setting up triggers")
    trigger_files = get_files(trigger_dir)
    execute_query(cursor, map_with_dir(trigger_dir, trigger_files))
    logger.debug("Triggers Added")


# Functions
def drop_functions(cursor, function_dir: str) -> None:
    """Remove the functions"""
    logger.debug("Dropping functions")
    execute_query(cursor, map_with_dir(
        function_dir, ["drop_all_functions.sql"]))
    logger.debug("Functions dropped")


def setup_functions(cursor, function_dir: str) -> None:
    """Create the functions"""
    logger.debug("Setting up Functions")
    function_files = get_files(function_dir)
    execute_query(cursor, map_with_dir(function_dir, function_files))
    logger.debug("Functions Added")


# Views
def drop_view(cursor, view_dir: str) -> None:
    """Remove all views"""
    logger.debug("Dropping views")
    execute_query(cursor, map_with_dir(view_dir, ["drop_all_views.sql"]))
    logger.debug("Views dropped")


def setup_view(cursor, view_dir: str) -> None:
    """Create all views"""
    logger.debug("Creating Views")
    view_files = get_files(view_dir)
    execute_query(cursor, map_with_dir(view_dir, view_files))
    logger.debug("Views created")


# Test data functions
def test_data(cursor, query: str, isPass: bool = True) -> tuple:
    """Test the query"""
    msg = "Passed when it should fail"
    p = True
    try:
        cursor.execute(query)
    except Exception as e:
        p = False
        msg = e

    # Flip if the target is to fail
    if not isPass:
        p = not p

    # Return bool, err msg
    return p, msg


def load_schema_success_data(test_path: str, cursor) -> list:
    """Load the data"""

    # Generate the file path
    file_paths = zip(map_with_dir(test_path, map(
        lambda x: x[0], FILES_TEST_MAP)), map(lambda x: x[1], FILES_TEST_MAP))

    # Load the data in order
    for path, table in file_paths:

        # Skip if file does not exist
        if not os.path.isfile(path):
            continue

        header, data = get_data(path)
        for index, item in enumerate(data):
            if not "".join(item.values()):
                continue
            q = generate_query(table, header, item)
            passed, msg = test_data(cursor, q)
            if not passed:
                logger.critical(
                    f"Fail Success Testcase: Row {index + 1} of {os.path.basename(path)}\nQuery: {q}\nError: {msg}")
                return


def load_schema_fail_data(test_path: str, cursor, db):
    """Load the fail data"""

    # Generate the file path
    file_paths = zip(map_with_dir(test_path, map(
        lambda x: x[0], FILES_TEST_MAP)), map(lambda x: x[1], FILES_TEST_MAP))

    # Store Success queries
    successes = []

    # Load the data in order
    for path, table in file_paths:

        # Skip if file does not exist
        if not os.path.isfile(path):
            continue

        _, data = get_data(path)

        for index, item in enumerate(data):

            # If it is empty, skip it
            if not "".join(item.values()):
                continue

            # Unpack the values
            isPass, remarks = item['outcome'] == 'pass', item['reason']
            del item['outcome']
            del item['reason']

            # Generate and test query
            q = generate_query(table, item.keys(), item)
            passed, msg = test_data(cursor, q, isPass)

            if isPass:
                successes.append(q)
            else:
                db.rollback()
                for d in successes:
                    test_data(cursor, d, True)

            # If passed continue
            if passed:
                continue

            # Throw an error
            logger.critical(
                f"Fail Failure Testcase: Row {index + 1} of {os.path.basename(path)}\nQuery: {q}\nError: {msg}\nRemarks: {remarks}")
            return


def load_custom_testcases(test_path: str, cursor) -> None:
    """Run all custom test cases"""

    # Generate the file path
    file_paths = map_with_dir(test_path, get_files(test_path))

    # Load each path
    for path in file_paths:

        # Get the json file
        with open(path) as file:
            data = json.loads(file.read())

        # Store vars
        isPass = data['pass']
        table_name = data['table_name']

        # Remove excess args
        del data['pass']
        del data['table_name']

        # Generate query
        q = generate_query(table_name, data.keys(), data)

        # Test the query
        passed, msg = test_data(cursor, q, isPass)
        if not passed:
            logger.critical(
                f'Failed test: Test file {os.path.basename(path)}\nQuery: {q}\nError: {msg}')


# Parsing functions
def parse_constants(host: str, port: str, dbname: str) -> tuple:
    """Parse the constants"""
    return host, int(port), dbname


def parse_credentials(username: str, password: str) -> tuple:
    """Parse the login credentials"""
    return username, password


def parse_dir(schemas: str, functions: str, triggers: str, views: str) -> tuple:
    """Parse the directory"""
    return schemas, functions, triggers, views


if __name__ == "__main__":
    # Main code for the test cases
    print("Loading Test")

    # Parse the config file
    parser = configparser.ConfigParser()
    parser.read(SETTINGS_DIRECTORY)
    const = parser["CONSTANTS"]
    HOST, PORT, DBNAME = parse_constants(**parser["CONSTANTS"])
    user, password = parse_credentials(**parser["CREDENTIALS"])
    schema_dir, function_dir, trigger_dir, view_dir = parse_dir(
        **parser["DIRECTORIES"])

    # Check if username exists
    if not user:
        user = input("Username: ")
        password = getpass()

    # Check if password exists
    elif not password:
        password = getpass()

    # Connect to the database
    with connect_db(HOST, PORT, user, password, DBNAME) as db:
        db.autocommit = True
        with db.cursor() as cursor:

            # Setup the sql env
            drop_triggers(cursor, trigger_dir)
            drop_functions(cursor, function_dir)
            drop_view(cursor, view_dir)
            drop_schema(cursor, schema_dir)
            setup_schema(cursor, schema_dir)
            setup_view(cursor, view_dir)
            setup_functions(cursor, function_dir)
            setup_triggers(cursor, trigger_dir)
            db.autocommit = False

    with connect_db(HOST, PORT, user, password, DBNAME) as db:
        with db.cursor() as cursor:
            # Positive test cases for schema (Cumulative)
            load_schema_success_data('./test data/schema test', cursor)
            db.rollback()

            # Run the negative test cases for schema Data
            load_schema_fail_data('./test data/schema fail', cursor, db)
            db.rollback()

            # Other TODO below
            # Positive test cases for triggers
            # db.rollback()

            # Run the negative test cases for triggers
            # db.rollback()

            # Positive test cases for view
            # db.rollback()

            # Run the negative test cases for view
            # db.rollback()

            # Load Custom Test cases
            load_custom_testcases("./test data/custom test cases", cursor)
            db.rollback()

            # Commit
            db.commit()

            # Unittest for functions
            BaseTest.DB = db
            BaseTest.CURSOR = cursor
            unittest.main()
