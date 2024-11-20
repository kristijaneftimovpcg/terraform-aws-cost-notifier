# terraform-aws-cost-notifier

### A Terraform module that calculates the daily, weekly, monthly, or annual costs for AWS services and generates a cost forecast(planned cost) for the current month.

## Usage

```hcl
module "cost_notifier" {
  project-name     = "projectName"
  calculation-type = "monthly" //   # daily, weekly, monthly, annual are the options
  cron-expression  = "cron(0 7 ? * MON *)" // 9:00AM every Monday
  aws-region       = "eu-central-1"
  sns-endpoint     = ["email-me@gmail.com", "email-me-2@gmail.com"]
  budget-threshold  = 100 // By setting this variable to a value greater than 0, Budgets will be created in AWS, and an alarm will be set up to monitor and notify based on predefined thresholds. The SNS endpoint(s) will be alerted if costs reach 80% of the threshold value.
}
```


### Budgets note - By configuring a 'budget-threshold', Budgets will be created in AWS, and an alarm will be set up to monitor and notify based on predefined thresholds. The SNS endpoint(s) will be alerted if costs reach 80% of the threshold value.


## Module Input Variables

| Name                    | Type                             | Default    | Description                                                                                                                 |
| ----------------------- | -------------------------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| cron-expression     | string                           |  `Not Set` |  The CloudWatch Schedule Expression to trigger the Lambda. _Required_.                |
| project-name                    | string                           |  `Not Set` |  The name of the project. _Required_.                                                                              |
| calculation-type                    | string                      |  `Not Set`     |  The type of costs we need (daily, weekly, monthly, annual are the options - detailed description below) . _Required_                                                                            |
| aws-region     | string                           |  `Not Set` |  The AWS region. _Required_              |
| sns-endpoint                  | list(string)                           |  `Not Set` | List of emails for SNS subscription. _Required_. |
| budget-threshold                 | number                          |  `Not Set` |  The budget threshold for the current month (detailed description above). _Optional_.|

<h3> -Daily calculates the cost for the previous day </h3>
<h3> -Monthly calculates the cost for the current month, up until today </h3>
<h3> -Weekly calculates the cost for the previous week </h3>
<h3> -Annual calculates the cost for the current year, up until today</h3>