#!/usr/bin/python3
import logging
import configparser
import datetime
import smtplib
import time
from email.message import EmailMessage

now = datetime.datetime.now()
tommorow = (now + datetime.timedelta(1))
config = configparser.ConfigParser()
config.read('/usr/local/bin/ozonesender/OzoneSender.conf')
smtp_server = config['Config']['smtp_server']
smtp_port = config['Config']['smtp_port']
password = config['Config']['email_password']
email_from  = config['Config']['email_from']
email_to = config['Config']['email_to']
email_subject = 'Ozone report ' + now.strftime("%Y.%m.%d")
path = config['Config']['path_to_dir']
filename = 'voz' + now.strftime("%b%y") + '.dat'
filepath = path + filename
retry_times = int(config['Config']['retry_times'])
retry_delay = int(config['Config']['retry_delay'])
logging.basicConfig(filename='/usr/local/bin/ozonesender/OzoneSender.log', level=logging.INFO, format='%(asctime)s %(message)s')

def oz_data_today(filepath):
    oz_today = []
    with open(filepath, 'r') as data:
        for line in data:
            if line[0] == '2':
                year = int(line[0:4])
                month = int(line[5:7])
                day = int(line[8:10])
                hour = int(line[11:13])
                f_date = ("%s.%s.%s" % (year, month, day))
                n_date = now.strftime("%Y.")+str(int(now.strftime("%m")))+'.'+str(int(now.strftime("%d")))
                t_date = tommorow.strftime("%Y.")+str(int(tommorow.strftime("%m")))+'.'+str(int(tommorow.strftime("%d")))
                if f_date == n_date or (f_date == t_date and hour < 3):
#                if (int(year) == now.year) and (int(month) == now.month) and (int(day) == now.day):
                    oz_today.append(line)
    oz_today = ''.join(oz_today)
    assert len(oz_today) > 0, "There is no ozone data for today"
    return oz_today

def send_email(smtp_server, smtp_port, e_pass, e_from, e_to, e_subject, e_text):
    msg = EmailMessage()
    msg.set_content(str(e_text))
    msg['Subject'] = str(e_subject)
    msg['From'] = e_from
    msg['To'] = e_to
    with smtplib.SMTP(smtp_server, smtp_port) as server:
#        server.set_debuglevel(1)
        server.starttls()
        server.login(e_from, e_pass)
        server.send_message(msg)
        server.quit()

def retry(func, *func_args, r_times, r_delay):
    for _ in range(r_times):
        try:
            result = func(*func_args)
            logging.info("Succesfully done %s" % func)
            break
        except Exception as err:
            logging.warning("%s. %s wasn't succesfull. Retrying %s times in %s seconds" % (err, func, r_times, r_delay))
            time.sleep(r_delay)

try:
    email_text = oz_data_today(filepath)
    print(email_text)
    logging.info("Today's ozone data parsed succesfully")
except FileNotFoundError as fnf_error:
    logging.warning("Please check file path. %s" % fnf_error)
except AssertionError as a_error:
    logging.warning("Please check todays ozone data lines in %s. %s" % (filepath, a_error))

retry(send_email, smtp_server, smtp_port, password, email_from, email_to, email_subject, email_text, r_times=retry_times, r_delay=retry_delay)
