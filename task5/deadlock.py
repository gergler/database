import sqlite3
import time
from threading import Thread

# connection = sqlite3.connect('sqlite.db')
#
# drop_table = '''DROP TABLE IF EXISTS lock1;'''
#
# create_table = '''CREATE TABLE lock1 (
#                                     id INTEGER PRIMARY KEY,
#                                     name TEXT NOT NULL);'''
#
# cursor = connection.cursor()
# print("База данных подключена к SQLite")
# cursor.execute(drop_table)
# cursor.execute(create_table)
# print("Таблица SQLite создана")
#
# cursor.execute("""INSERT INTO lock1 (id, name)  VALUES  (1, 'Coca Cola')""")
# cursor.execute("""INSERT INTO lock1 (id, name)  VALUES  (2, 'Coca Cola')""")

def lock1():
    connection1 = sqlite3.connect('sqlite.db')
    connection1.create_function("sleep", 1, time.sleep)
    cursor1 = connection1.cursor()
    try:
        cursor1.execute("""UPDATE lock1 SET name =  'Pepsi' WHERE id = 1""")
        cursor1.execute("""SELECT sleep(10)""")
        cursor1.execute("""UPDATE lock1 SET name =  'Nesti' WHERE id = 2""")
    except sqlite3.Error as error:
        print(error)
    finally:
        cursor1.close()
        if (connection1):
            connection1.close()


def lock2():
    connection2 = sqlite3.connect('sqlite.db')
    connection2.create_function("sleep", 1, time.sleep)
    cursor2 = connection2.cursor()
    try:
        cursor2.execute("""UPDATE lock1 SET name =  'Fanta' WHERE id = 2""")
        cursor2.execute("""SELECT sleep(10)""")
        cursor2.execute("""UPDATE lock1 SET name =  'Milkis' WHERE id = 1""")
    except sqlite3.Error as error:
        print(error)
    finally:
        cursor2.close()
        if (connection2):
            connection2.close()


thread1 = Thread(target=lock1, args=())
thread2 = Thread(target=lock2, args=())

thread1.start()
thread2.start()

thread1.join()
thread2.join()
