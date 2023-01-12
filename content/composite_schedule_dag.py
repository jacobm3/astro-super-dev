from datetime import datetime,timedelta
from airflow.operators.dummy_operator import DummyOperator
from airflow import DAG, Dataset
from airflow.decorators import dag, task

composite_sched_dataset = Dataset('composite_sched')

default_args={ "owner": "Data Engineering" }

# Traditional Operators
with DAG(
    "composite_sched_mod6_weekdays",
    schedule='*/6 * * * 1-5',
    start_date=datetime(2022, 12, 1),
    catchup=False,
    default_args=default_args,
):
    t = DummyOperator(task_id='dummy_task', outlets=[composite_sched_dataset])

with DAG(
    "composite_sched_mod5_wednesday",
    schedule='*/5 * * * 3',
    start_date=datetime(2022, 12, 1),
    catchup=False,
    default_args=default_args,
):
    t = DummyOperator(task_id='dummy_task', outlets=[composite_sched_dataset])

with DAG(
    "composite_sched_noon_sunday",
    schedule='0 12 * * 0',
    start_date=datetime(2022, 12, 1),
    catchup=False,
    default_args=default_args,
):
    t = DummyOperator(task_id='dummy_task', outlets=[composite_sched_dataset])


# TaskFlow API
@dag(
    default_args=default_args,
    schedule=[composite_sched_dataset],
    start_date=datetime(2022, 12, 1),
    catchup=False,
)
def dag_on_composite_sched(default_args=default_args):

    @task()
    def something_useful():
        data_string = '{"1001": 301.27, "1002": 433.21, "1003": 502.22}'
        order_data_dict = json.loads(data_string)
        return order_data_dict

dag_on_composite_sched()

