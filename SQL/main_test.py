#!/usr/bin/python3
import os
import psycopg2
import configparser
import logging
from getpass import getpass


# Define constants
SETTINGS_DIRECTORY = "settings.cfg"

# Make the logger
logger = logging.Logger("Logs")
logger.setLevel(logging.INFO)

# DB functions
def connect_db(host: str, port: int, user: str, password: str, dbname: str):
    """Connect to the database and return the database object"""
    conn = psycopg2.connect(
        database=dbname, host=host, port=port, user=user, password=password
    )
    return conn


# General functions
def get_query(path: str) -> str:
    """Get the query from the file"""
    with open(path) as file:
        return file.read()


def get_files(directory: str) -> list:
    """Get the files in the folder"""
    if not os.path.isdir(directory):
        raise NotADirectoryError(f"{directory} is not a directory")
    return [x[-1] for x in os.walk(directory)][0]


def execute_query(cursor, query_paths: list) -> None:
    """Read query from list of files and execute them"""
    for path in query_paths:
        query = get_query(path)
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
    execute_query(cursor, map_with_dir(schema_dir, map(lambda x: f"{x}.sql", filenames)))
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
    execute_query(cursor, map_with_dir(function_dir, ["drop_all_functions.sql"]))
    logger.debug("Functions dropped")


def setup_functions(cursor, function_dir: str) -> None:
    """Create the functions"""
    logger.debug("Setting up Functions")
    function_files = get_files(function_dir)
    print(function_files)
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
    print(
        """
        Connect to NUS Posgresql
        Make sure you are on SoC VPN
        Not sure if it will work outside SoC
        """
    )

    # Parse the config file
    parser = configparser.ConfigParser()
    parser.read(SETTINGS_DIRECTORY)
    const = parser["CONSTANTS"]
    HOST, PORT, DBNAME = parse_constants(**parser["CONSTANTS"])
    user, password = parse_credentials(**parser["CREDENTIALS"])
    schema_dir, function_dir, trigger_dir, view_dir = parse_dir(**parser["DIRECTORIES"])

    # Check if username exists
    if not user:
        user = input("Username: ")
        password = getpass()

    # Check if password exists
    elif not password:
        password = getpass()

    # Connect to the database
    with connect_db(HOST, PORT, user, password, DBNAME) as db:
        cursor = db.cursor()

        # Setup the sql env
        try:
            drop_triggers(cursor, trigger_dir)
            drop_functions(cursor, function_dir)
            drop_view(cursor, view_dir)
            drop_schema(cursor, schema_dir)
        except Exception as e: 
            logging.critical(f"Error with Dropping: {e}")

        try:
            setup_schema(cursor, schema_dir)
            setup_view(cursor, view_dir)
            setup_functions(cursor, function_dir)
            setup_triggers(cursor, trigger_dir)
        except Exception as e:
            logging.critical(f"Error with adding: {e}")

        # TODO Run the test cases

        # Commit
        db.commit()
