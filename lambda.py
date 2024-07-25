import boto3
import datetime
import os

sns_topic_arn = os.getenv('sns_topic_arn')
region = os.getenv('region')
project_name = os.getenv('project_name')
calculation_type = os.getenv('calculation_type')
account_id = os.getenv('account_id')

def lambda_handler(event, context):
    ce = boto3.client('ce', region_name=region)
        
    #Function to get the dates for calculating the cost, depending on the calculation type (daily, weekly, monthly)
    def get_cost_dates():
        end_date = datetime.date.today()
        
        if calculation_type == 'daily': 
            start_date = end_date - datetime.timedelta(days=1) # this calculates the cost for the previous day
        elif calculation_type == 'weekly': 
            start_date = end_date - datetime.timedelta(days=7) # this calculates the cost for the previous week
        elif calculation_type == 'monthly': 
            start_date = end_date.replace(day=1) # this calculates the cost for the current month, up until today
        else: 
            start_date = end_date.replace(day=1) # the default value is calculation for the current month, up until today
        
        return start_date, end_date
    
    #Function to get the actual cost depending on the calculation type
    def get_actual_cost(start_date, end_date):
        actual_cost = ce.get_cost_and_usage(
            TimePeriod={
                'Start': start_date.strftime('%Y-%m-%d'),
                'End': end_date.strftime('%Y-%m-%d')
            },
            Granularity='MONTHLY',
            Metrics=['UnblendedCost'], 
        )   

        total_actual_cost = float(actual_cost['ResultsByTime'][0]['Total']['UnblendedCost']['Amount'])
        return round(total_actual_cost, 2)
    
    #Function to get the forecast dates for the current month
    def get_forecast_dates():
        start_date = datetime.date.today() # We need to set the start date to the current date for calculating the forecast
        
        next_month = start_date.replace(day=28) + datetime.timedelta(days=4)  # Move to the next month
        end_date = next_month.replace(day=1) - datetime.timedelta(days=1)  # Last day of the current month
        
        return start_date, end_date

    #Function to get the forecast cost for the current month
    def get_forecast_cost(start_date, end_date):
        forecast_cost = ce.get_cost_forecast(
            TimePeriod={
                'Start': start_date.strftime('%Y-%m-%d'),
                'End': end_date.strftime('%Y-%m-%d')
            },
            Granularity='MONTHLY',
            Metric='UNBLENDED_COST', 
        )
        
        total_forecast_cost = float(forecast_cost['ForecastResultsByTime'][0]['MeanValue'])
        return round(total_forecast_cost, 2)
    
    start_date, end_date = get_cost_dates()
    actual_cost = get_actual_cost(start_date, end_date)
    
    forecast_start_date, forecast_end_date = get_forecast_dates()
    forecast_cost = get_forecast_cost(forecast_start_date, forecast_end_date)
    
    message = (
        f"{project_name} costs for account: {account_id}\n"
        f"Forecast cost for this month is: ${forecast_cost}\n"
        f"{calculation_type.capitalize()} cost for {start_date} to {end_date}: ${actual_cost}"
    )
    
    # Send an email with sns topic
    sns = boto3.client('sns', region_name=region)
    sns.publish(TopicArn=sns_topic_arn, Message=message)
