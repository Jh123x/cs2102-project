import os


func_names = [
    "add_employee",
    "remove_employee",
    "add_customer",
    "update_credit_card",
    "add_course",
    "find_instructors",
    "get_available_instructors",
    "find_rooms",
    "get_available_rooms",
    "add_course_offering",
    'add_course_package',
    'get_available_course_packages',
    'buy_course_package',
    'get_my_course_package',
    'get_available_course_offerings',
    'get_available_course_sessions',
    'register_session',
    'get_my_registrations',
    'update_course_session',
    'cancel_registration',
    'update_instructor',
    'update_room',
    'remove_session',
    'add_session',
    'pay_salary',
    'promote_courses',
    'top_packages',
    'popular_courses',
    'view_summary_report',
    'view_manager_report'
]


def create_files():
    """Create the file for the folder structure"""
    os.makedirs("functions")
    os.makedirs("test")
    for name in func_names:
        with open(f"functions\\{name}.sql", 'w') as file:
            pass
        with open(f"test\\{name}Test.sql", 'w') as file:
            pass
        with open(f"test\\{name}Test.csv", 'w') as file:
            pass
