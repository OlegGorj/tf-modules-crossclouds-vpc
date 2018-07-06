[![Codacy Badge](https://api.codacy.com/project/badge/Grade/176573f425d147eabd9694b3674e1c05)](https://app.codacy.com/app/oleggorj/tf-modules-crossclouds-vpc?utm_source=github.com&utm_medium=referral&utm_content=OlegGorj/tf-modules-crossclouds-vpc&utm_campaign=badger)
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2FOlegGorj%2Ftf-modules-crossclouds-vpc.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2FOlegGorj%2Ftf-modules-crossclouds-vpc?ref=badge_shield)
[![GitHub Issues](https://img.shields.io/github/issues/OlegGorJ/tf-modules-crossclouds-vpc.svg)](https://github.com/OlegGorJ/tf-modules-crossclouds-vpc/issues)
[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/OlegGorJ/tf-modules-crossclouds-vpc.svg)](http://isitmaintained.com/project/OlegGorJ/tf-modules-crossclouds-vpc "Average time to resolve an issue")
[![Percentage of issues still open](http://isitmaintained.com/badge/open/OlegGorJ/tf-modules-crossclouds-vpc.svg)](http://isitmaintained.com/project/OlegGorJ/tf-modules-crossclouds-vpc "Percentage of issues still open")

# Terraform Modules to create multi-cloud VPN with AWS and GCP

This project is intended to use Terraform for automated deployment of network infrastructure in both Google Cloud Platform (GCP) and Amazon Web Services (AWS). This is a multi-cloud VPN setup.

Note: this repo is WIP, use at your own risk.


## Quick Start

1. Initialize GCP environment

This step creates/updates terraform variable file `./terraform/terraform.tfvars` with GCP variables and generates terraform GCP backend file `./terraform/backend.tf`

```
cd tf-modules-crossclouds-vpc
./tf_init.sh GCP tf-admin-dev-xxxxxxxx dev ~/.config/gcloud/tf-admin.json

```

2. Initialize AWS environment

This step creates/updates terraform variable file `./terraform/terraform.tfvars` with AWS variables.

```
cd tf-modules-crossclouds-vpc
./tf_init.sh AWS dev ~/.aws/credentials

```



---

## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2FOlegGorj%2Ftf-modules-crossclouds-vpc.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2FOlegGorj%2Ftf-modules-crossclouds-vpc?ref=badge_large)
