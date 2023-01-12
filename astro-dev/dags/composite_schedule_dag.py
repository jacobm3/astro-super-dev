from datetime import datetime,timedelta
from airflow.operators.dummy_operator import DummyOperator
from airflow import DAG, Dataset
from airflow.decorators import dag, task
import json

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
    def extract():
        """
        #### Extract task
        A simple "extract" task to get data ready for the rest of the
        pipeline. In this case, getting data is simulated by reading from a
        hardcoded JSON string.
        """
        data_string = '{"1001": 301.27, "1002": 433.21, "1003": 502.22}'

        order_data_dict = json.loads(data_string)
        return order_data_dict

    @task(multiple_outputs=True) # multiple_outputs=True unrolls dictionaries into separate XCom values
    def transform(order_data_dict: dict):
        """
        #### Transform task
        A simple "transform" task which takes in the collection of order data and
        computes the total order value.
        """
        total_order_value = 0

        for value in order_data_dict.values():
            total_order_value += value

        return {"total_order_value": total_order_value}

    @task()
    def load(total_order_value: float):
        """
        #### Load task
        A simple "load" task that takes in the result of the "transform" task and prints it out,
        instead of saving it to end user review
        """

        print(f"Total order value is: {total_order_value:.2f}")

    order_data = extract()
    order_summary = transform(order_data)
    load(order_summary["total_order_value"])

dag_on_composite_sched()
