# terraform-aws-cost-notifier

Terraform module to calculate the daily, weekly or monthly cost in AWS, and generates the forecast cost for the current month.


## Usage

```hcl
module "cost_notifier" {
  source           = "https://github.com/kristijaneftimovpcg/aws-cost-notifier"
  project-name     = "projectName"
  calculation-type = "monthly" //   # daily, weekly, monthly are the options
  cron-expression  = "cron(0 7 ? * MON *)" // 9:00AM every Monday
  aws-region       = "eu-central-1"
  sns-endpoint     = "email-me@gmail.com"
  budget-threshold  = 100 // the sns-endpoint will be notified if cost reaches 80% of this value (Optional)
}
```

## Module Input Variables

| Name                    | Type                             | Default    | Description                                                                                                                 |
| ----------------------- | -------------------------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| cron-expression     | string                           |  `Not Set` |  The CloudWatch Schedule Expression to trigger the Lambda. _Required_.                |
| project-name                    | string                           |  `Not Set` |  The name of the project. _Required_.                                                                              |
| calculation-type                    | string                      |  `Not Set`     |  The type of costs we need (daily, weekly, monthly are the options - detailed description below) . _Required_                                                                            |
| aws-region     | string                           |  `Not Set` |  The AWS region. _Required_              |
| sns-endpoint                  | string                           |  `Not Set` |  The email for SNS subscription. _Required_. |
| budget-threshold                 | number                          |  `Not Set` |  The budget for the current month. _Optional_.|

<h3> -Daily calculates the cost for the previous day </h3>
<h3> -Monthly calculates the cost for the current month, up until today </h3>
<h3> -Weekly calculates the cost for the previous week </h3>