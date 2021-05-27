import datetime
import random
import config
import telebot
from telebot import types
import sqlite3

bot = telebot.TeleBot(config.token)

# Creates SQLite database to store info.
conn = sqlite3.connect('pydb.db', check_same_thread=False)
cur = conn.cursor()

cur.executescript('''CREATE TABLE IF NOT EXISTS userdata
    (
    Id INTEGER PRIMARY KEY, 
    Name VARCHAR,
    Age TEXT,
    Sex VARCHAR);'''
                  )

cur.executescript('''CREATE TABLE IF NOT EXISTS echodata
    (
    Id INTEGER NOT NULL,
    Time TIMESTAMP, 
    Text VARCHAR,
    FOREIGN KEY (Id) REFERENCES userdata(Id));'''
                  )

cur.executescript('''CREATE TABLE IF NOT EXISTS picdata
    (
    Id INTEGER NOT NULL,
    Theme VARCHAR, 
    URL VARCHAR PRIMARY KEY,
    FOREIGN KEY (Id) REFERENCES userdata(Id));'''
                  )

cur.execute('''DROP TABLE IF EXISTS questionnaire;''')
cur.execute('''DROP TABLE IF EXISTS question;''')

cur.executescript('''CREATE TABLE IF NOT EXISTS question
    (
    Num INTEGER SERIAL, 
    Id INTEGER NOT NULL,
    Theme VARCHAR,
    Answer VARCHAR,
    Question VARCHAR,
    FOREIGN KEY (Id) REFERENCES userdata (Id));'''
                  )

cur.executescript('''CREATE TABLE IF NOT EXISTS questionnaire
    (
    Num INTEGER SERIAL, 
    Id INTEGER NOT NULL,
    Theme VARCHAR,
    Answer VARCHAR,
    Question VARCHAR,
    FOREIGN KEY (Id) REFERENCES userdata (Id));'''
                  )


user_data = {}
pic_data = {}
talki_q = {}


@bot.message_handler(commands=['help'])
def help(message):
    msg = bot.send_message(message.chat.id, 'Hello! I am a Talki, look what I can:\n'
                                            '(use / before commands)\n'
                                            'start - user registration\n'
                                            'reset - deleting a user from the database\n'
                                            'addpic - adding an image via url\n'
                                            'sentpic - sending a picture\n'
                                            'echo - echo message recording with time storing\n'
                                            '\t\t\t\tto stop recording sent: stop (without slash)\n'
                                            '\t\t\t\tto send the recorded data: senddata\n'
                                            '\t\t\t\tto dump records: empty\n'
                                            'talki - start personality test :)\n'
                                            'question - add question\n'
                                            'delq - deleted your questions\n'
                                            'delansw - deleted your questionnaire\n')


@bot.message_handler(commands=['talki'])
def talki_start(message):
    try:
        if len(cur.execute('''SELECT Name FROM userdata WHERE Id = ?''', (message.from_user.id,)).fetchone()) > 0:
            name = cur.execute('''SELECT Name FROM userdata WHERE Id = ?''', (message.from_user.id,)).fetchone()
            msg = bot.send_message(message.chat.id, 'Lets start questionnaire, ' + name[0] + '! (press any key)')
            bot.register_next_step_handler(msg, talki_question)
        else:
            msg = bot.send_message(message.chat.id, 'Sign up first!')
            bot.register_next_step_handler(msg, send_welcome)
    except Exception as e:
        bot.send_message(message.chat.id, 'oooops, smth went wrong')


def talki_question(message):
    # try:
        user_id = message.from_user.id
        quest = cur.execute('''SELECT Question FROM question WHERE Question NOT IN (SELECT Question FROM questionnaire WHERE Id = ?)''',
            (user_id)).fetchall()
        print(1, quest)
        if len(quest) > 0:
            markup = types.ReplyKeyboardMarkup(one_time_keyboard=True)
            markup.add('Yes', 'No', 'Stop')
            rand_q = random.choice(quest)
            cur.execute('''INSERT INTO questionnaire (Id, Question) VALUES (?, ?)''',
                        (user_id, random.choice(quest)))
            conn.commit()
            print(rand_q)
            msg = bot.send_message(message.chat.id, rand_q, reply_markup=markup)
            bot.register_next_step_handler(msg, talki_answer)
        else:
            person = cur.execute('''SELECT Answer FROM questionnaire WHERE Answer = 'Yes' AND QId = ?''',
                                 (user_id,)).fetchall()
            if (len(person) > 0) and (len(person) < 5):
                person = 'Introvert'
            else:
                person = 'Extravert'
            msg = bot.send_message(message.chat.id, 'You have already passed the personality test, you ' + person)
    # except Exception as e:
    #     bot.send_message(message.chat.id, 'oooops, smth went wrong')


def talki_answer(message):
    # try:
        user_id = message.from_user.id
        answer = message.text
        if answer in (u'Yes', u'No'):
            cur.execute('''INSERT INTO questionnaire (Answer) VALUES (?) WHERE Answer = NULL AND Id = ?''',
                        (answer, user_id))
            conn.commit()
            pr = cur.execute('''SELECT Question FROM questionnaire''').fetchall()
            print(pr)
            quest = cur.execute('''SELECT Question FROM question WHERE Question NOT IN (SELECT Question FROM questionnaire WHERE Id = ?)''',
                (user_id,)).fetchall()
            print(2, quest)
            if len(quest) > 0:
                markup = types.ReplyKeyboardMarkup(one_time_keyboard=True)
                markup.add('Yes', 'No', 'Stop')
                rand_q = random.choice(quest)
                cur.execute('''INSERT INTO questionnaire (Id, Question) VALUES (?, ?)''',
                            (user_id, rand_q))
                conn.commit()
                msg = bot.send_message(message.chat.id, rand_q, reply_markup=markup)
                bot.register_next_step_handler(msg, talki_answer)
            else:
                person = cur.execute('''SELECT Answer FROM questionnaire WHERE Answer = 'Yes' AND Id = ?''',
                                     (message.from_user.id,)).fetchall()
                count_q = cur.execute('''SELECT Question FROM question''').fetchall()
                if len(person) < len(count_q) / 2:
                    person = 'Introvert'
                else:
                    person = 'Extravert'
            msg = bot.send_message(message.chat.id, 'Congrats! Your personality is ' + person)
        elif answer == u'Stop':
            msg = bot.send_message(message.chat.id, 'Your data has been recorded, come back later, we will continue!')
        else:
            msg = bot.send_message(message.chat.id, 'I do not know such cases, try again')
            bot.register_next_step_handler(msg, talki_answer)
    # except Exception as e:
    #     bot.send_message(message.chat.id, 'oooops, smth went wrong')


@bot.message_handler(commands=['delansw'])
def delansw(message):
    try:
        cur.execute('''DELETE FROM questionnaire WHERE Id = ?''', (message.from_user.id,))
        conn.commit()
        msg = bot.send_message(message.chat.id, "Your questionnaire was deleted!")
    except Exception as e:
        bot.send_message(message.chat.id, 'oooops, sorry, we can not start over')


@bot.message_handler(commands=['delq'])
def delq(message):
    try:
        cur.execute('''DELETE FROM question WHERE Id = ?''', (message.from_user.id,))
        conn.commit()
        msg = bot.send_message(message.chat.id, "Your question's was deleted!")
    except Exception as e:
        bot.send_message(message.chat.id, 'oooops, sorry, we can not start over')


@bot.message_handler(commands=['question'])
def talki_theme(message):
    try:
        markup = types.ReplyKeyboardMarkup(one_time_keyboard=True)
        markup.add('Good', 'Bad')
        msg = bot.send_message(message.chat.id, 'What is your theme: ', reply_markup=markup)
        bot.register_next_step_handler(msg, talki_add)
    except Exception as e:
        bot.send_message(message.chat.id, 'oooops, smth went wrong')


def talki_add(message):
    try:
        answer = message.text
        if answer in (u'Good', u'Bad'):
            msg = bot.send_message(message.chat.id, 'What is your question: ')
            bot.register_next_step_handler(msg, talki_new_q)
    except Exception as e:
        bot.send_message(message.chat.id, 'oooops, smth went wrong')


def talki_new_q(message):
    try:
        question = message.text
        if (cur.execute('''SELECT Question FROM question WHERE Question = (?)''', (question,)).fetchone() == None):
            cur.execute('''INSERT INTO question (Id, Question) VALUES (?, ?)''', (message.from_user.id, question))
            conn.commit()
            msg = bot.send_message(message.chat.id, 'Your question was added! Thanks!')
        elif len(cur.execute('''SELECT Question FROM question WHERE Question = (?)''', (question,)).fetchone()) > 0:
            msg = bot.send_message(message.chat.id, 'That question was added early! Sorry, try again!')
            bot.register_next_step_handler(msg, talki_add)
        else:
            cur.execute('''INSERT INTO question (Id, Question) VALUES (?, ?)''', (message.from_user.id, question))
            conn.commit()
            msg = bot.send_message(message.chat.id, 'Your question was added! Thanks!')
    except Exception as e:
        bot.send_message(message.chat.id, 'oooops, smth went wrong')


@bot.message_handler(commands=['sentpic'])
def what_pic(message):
    try:
        markup = types.ReplyKeyboardMarkup(one_time_keyboard=True)
        markup.add('Happy', 'Sad')
        msg = bot.send_message(message.chat.id, 'What topic is your image on?', reply_markup=markup)
        bot.register_next_step_handler(msg, send_picture)
    except Exception as e:
        bot.send_message(message.chat.id, 'oooops, smth went wrong')


def send_picture(message):
    try:
        theme = message.text
        if (theme == u'Happy') or (theme == u'Sad'):
            pic = cur.execute('''SELECT URL FROM picdata WHERE Theme = ? and URL IS NOT NULL''', (theme,)).fetchall()
            conn.commit()
            msg = bot.send_message(message.chat.id, random.choice(pic))
        else:
            raise Exception("Unknown theme")
    except Exception as e:
        bot.send_message(message.chat.id, 'oooops, smth went wrong')


@bot.message_handler(commands=['addpic'])
def pic(message):
    try:
        markup = types.ReplyKeyboardMarkup(one_time_keyboard=True)
        markup.add('Happy', 'Sad')
        msg = bot.send_message(message.chat.id, 'What topic is your image on?', reply_markup=markup)
        bot.register_next_step_handler(msg, add_theme)
    except Exception as e:
        bot.send_message(message.chat.id, 'oooops, smth went wrong')


def add_theme(message):
    try:
        user_id = message.from_user.id
        theme = message.text
        pic_data[user_id] = Pic(theme)
        if (theme == u'Happy') or (theme == u'Sad'):
            msg = bot.send_message(message.chat.id, 'Now sent URL:')
            bot.register_next_step_handler(msg, add_URL)
        else:
            raise Exception("Unknown theme")
    except Exception as e:
        bot.send_message(message.chat.id, 'oooops, smth went wrong')


def add_URL(message):
    try:
        user_id = message.from_user.id
        picture = pic_data[user_id]
        picture.url = message.text
        cur.execute('''INSERT INTO picdata (Id, Theme, URL) VALUES(?, ?)''', (user_id, picture.theme, picture.url))
        conn.commit()
        msg = bot.send_message(message.chat.id, 'Good job! Your picture was added :)')
    except Exception as e:
        bot.send_message(message.chat.id, 'oooops, can not add pic URL')


@bot.message_handler(commands=['start'])
def send_welcome(message):
    us_id = message.from_user.id
    if len(cur.execute('''SELECT Id FROM userdata WHERE Id = ?''', (us_id,)).fetchall()) > 0:
        us = cur.execute('''SELECT Name, Age, Sex FROM userdata WHERE id = ?''', (us_id,)).fetchone()
        conn.commit()
        msg = bot.send_message(message.chat.id,
                               'Welcome to the party, ' + us[0] + ', long time no see you!' + '\nAge: ' + us[
                                   1] + '\nSex: ' + us[2])
    else:
        msg = bot.send_message(message.chat.id, 'Welcome to the party, what is your name?')
        bot.register_next_step_handler(msg, process_name_step)


def process_name_step(message):
    try:
        user_id = message.from_user.id
        user_data[user_id] = User(message.text)
        msg = bot.send_message(message.chat.id, 'How old are you?')
        bot.register_next_step_handler(msg, process_age_step)
    except Exception as e:
        bot.send_message(message.chat.id, 'oooops, smth went wrong')


def process_age_step(message):
    try:
        user_id = message.from_user.id
        age = message.text
        if not age.isdigit():
            msg = bot.send_message(message.chat.id, 'Age should be a number. How old are you?')
            bot.register_next_step_handler(msg, process_age_step)
            return
        user = user_data[user_id]
        user.age = age
        markup = types.ReplyKeyboardMarkup(one_time_keyboard=True)
        markup.add('Male', 'Female')
        msg = bot.send_message(message.chat.id, 'What is your gender?', reply_markup=markup)
        bot.register_next_step_handler(msg, process_sex_step)
    except Exception as e:
        bot.send_message(message.chat.id, 'oooops, smth went wrong')


def process_sex_step(message):
    try:
        user_id = message.from_user.id
        sex = message.text
        user = user_data[user_id]
        if (sex == u'Male') or (sex == u'Female'):
            user.sex = sex
        else:
            raise Exception("Unknown sex")
        cur.execute('''INSERT INTO userdata (Id, Name, Age, Sex) VALUES (?, ?, ?, ?)''',
                    (user_id, user.name, user.age, user.sex))
        conn.commit()
        bot.send_message(user_id, 'Nice to meet you, ' + user.name + '\nAge:' + str(user.age) + '\nSex:' + user.sex)
    except Exception as e:
        bot.send_message(message.chat.id, 'oooops, smth went wrong')


@bot.message_handler(commands=['reset'])
def reset(message):
    try:
        cur.execute('''DELETE FROM userdata WHERE Id = ?''', (message.from_user.id,))
        conn.commit()
        msg = bot.send_message(message.chat.id, "Well, let's start again! (press any key)")
        bot.register_next_step_handler(msg, send_welcome)
    except Exception as e:
        bot.send_message(message.chat.id, 'oooops, sorry, we can not start over')


@bot.message_handler(commands=['echo'])
def echo_bot(message):
    try:
        if message.text == 'senddata':
            data = cur.execute('''SELECT Text FROM echodata WHERE Id = ?''', (message.from_user.id,)).fetchall()
            t = cur.execute('''SELECT Time FROM echodata WHERE Id = ?''', (message.from_user.id,)).fetchall()
            for i in range(len(data)):
                msg = bot.send_message(message.chat.id, data[i])
                msg = bot.send_message(message.chat.id, t[i])
        if message.text == 'empty':
            data = cur.execute('''DELETE FROM echodata''')
            conn.commit()
            msg = bot.send_message(message.chat.id, 'empty echodata')
        if message.text == 'stop':
            msg = bot.send_message(message.chat.id, 'stop echo')
        else:
            cur.execute('''INSERT INTO echodata (Id, Time, Text) VALUES (?, ?, ?)''',
                        (message.from_user.id, datetime.datetime.now(), message.text))
            conn.commit()
            msg = bot.send_message(message.chat.id, message.text)
            bot.register_next_step_handler(msg, echo_bot)
    except Exception as e:
        bot.send_message(message.chat.id, 'oooops, smth went wrong')


class User:
    def __init__(self, name):
        self.name = name
        self.age = None
        self.sex = None


class Pic:
    def __init__(self, theme):
        self.theme = theme
        self.url = None


class Question:
    def __init__(self, question):
        self.question = question


# Enable saving next step handlers to file "./.handlers-saves/step.save".
# Delay=2 means that after any change in next step handlers (e.g. calling register_next_step_handler())
# saving will hapen after delay 2 seconds.
bot.enable_save_next_step_handlers(delay=2)

# Load next_step_handlers from save file (default "./.handlers-saves/step.save")
# WARNING It will work only if enable_save_next_step_handlers was called!
bot.load_next_step_handlers()

if __name__ == '__main__':
    bot.polling(none_stop=True)
