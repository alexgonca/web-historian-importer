import psycopg2
from psycopg2 import extras
from sshtunnel import SSHTunnelForwarder
import configparser

CREATE_TABLE_WEB_HISTORIAN_DATAPOINT = """
create table if not exists web_historian_datapoint (
    id integer primary key,
    source varchar,
    created timestamp with time zone,
    recorded timestamp with time zone,
    url varchar,
    title varchar,
    domain varchar,
    wave integer
)
"""

SELECT_DATAPOINTS = """
select
    id,
    source,
    created,
    recorded,
    properties->>'url' as url,
    properties->>'title' as title,
    properties->>'domain' as domain
from
    passive_data_kit_datapoint
where
    id > {max_id}
order by id
"""

SELECT_MAX_DATAPOINT_ID = """
select
    max(id) as max_id
from
    web_historian_datapoint
"""

INSERT_DATAPOINT = """
insert into web_historian_datapoint
(id, source, created, recorded, url, title, domain)
values
(%s, %s, %s, %s, %s, %s, %s)
"""


def import_data(cap_the_results=True):
    config = configparser.ConfigParser()
    config.read('config.ini')

    primary_database = psycopg2.connect(database=config['primary_db']['database'],
                                        user=config['primary_db']['username'],
                                        password=config['primary_db']['password'],
                                        host=config['primary_db']['host'],
                                        port=5432)

    cursor_primary_database = primary_database.cursor(cursor_factory=extras.DictCursor)
    cursor_primary_database.execute(CREATE_TABLE_WEB_HISTORIAN_DATAPOINT)
    primary_database.commit()

    web_historian_server = SSHTunnelForwarder(
        (config['web_historian_vm']['address'], 22),
        ssh_private_key=config['web_historian_vm']['private_key_path'],
        ssh_username=config['web_historian_vm']['username'],
        ssh_private_key_password=config['web_historian_vm']['private_key_passphrase'],
        remote_bind_address=('localhost', 5432))
    web_historian_server.start()

    web_historian_database = psycopg2.connect(database=config['web_historian_db']['database'],
                                              user=config['web_historian_db']['username'],
                                              password=config['web_historian_db']['password'],
                                              host='localhost',
                                              port=web_historian_server.local_bind_port)
    cursor_primary_database.execute(SELECT_MAX_DATAPOINT_ID)
    max_datapoint = cursor_primary_database.fetchone()

    if cap_the_results:
        select_datapoints = SELECT_DATAPOINTS + " limit 100000"
    else:
        select_datapoints = SELECT_DATAPOINTS

    new_web_historian_records = web_historian_database.cursor(cursor_factory=extras.DictCursor)
    if max_datapoint['max_id'] is None:
        new_web_historian_records.execute(select_datapoints.format(max_id=0))
    else:
        new_web_historian_records.execute(select_datapoints.format(max_id=max_datapoint['max_id']))
    for new_record in new_web_historian_records.fetchall():
        cursor_primary_database.execute(INSERT_DATAPOINT, (new_record['id'],
                                                           new_record['source'],
                                                           new_record['created'],
                                                           new_record['recorded'],
                                                           new_record['url'],
                                                           new_record['title'],
                                                           new_record['domain']))
    primary_database.commit()
    primary_database.close()
    web_historian_database.close()
    web_historian_server.stop()


if __name__ == "__main__":
    import_data(cap_the_results=True)
