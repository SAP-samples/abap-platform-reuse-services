# Reuse services in ABAP Cloud
<!-- Please include descriptive title -->

<!--- Register repository https://api.reuse.software/register, then add REUSE badge:
[![REUSE status](https://api.reuse.software/badge/github.com/SAP-samples/REPO-NAME)](https://api.reuse.software/info/github.com/SAP-samples/REPO-NAME)
-->

## Description

In this repository you will find sample code that shows how to work with the following reuse services:   

- Number Ranges
- Change Documents
- Adobe Forms Service

The repository contains a simple sample RAP business objects to create sales orders and items. The semantic key for the sales orders is drawn from a _number range object_. Changes to two fields of the sales order are recorded using a _change document object_ and to data elements for the _total amount_ and the _overall status_ that have been configured appropriately to record changes.  

Using an action the sample also shows how content of a sales order entity including its items can be used to fill a form from the _Adobe Forms Service_ to create a PDF document.  

### Number Ranges

When you create a sales order a new number will be drawn from a number range. The RAP business object uses early numbering.

### Change Documents

The repository contains a change document object based on the two underlying tables that are used to store the sales order data and the data of the items.  
Two fields **Amount** and **Overall Status** of the sales order data table use data elements where the _Change Documeng Logging_ has been enabled. Only changes are recorded, not the inital values.  
That means that after you have created a sales order and change an item or add an item the total amaount will be changed as well and this change will be recorded and displayed in the Fiori Elements OData V4 app.

## Requirements

- Adobe Forms Service

## Download and Installation

Create a package, e.g. **'ZREUSE_SERVICES_002'** and link this package with the URL of this repository.

## Known Issues
<!-- You may simply state "No known issues. -->

No known issues.   

## How to obtain support
[Create an issue](https://github.com/SAP-samples/abap-platform-reuse-services/issues) in this repository if you find a bug or have questions about the content.
 
For additional support, [ask a question in SAP Community](https://answers.sap.com/questions/ask.html).

## Contributing
If you wish to contribute code, offer fixes or improvements, please send a pull request. Due to legal reasons, contributors will be asked to accept a DCO when they create the first pull request to this project. This happens in an automated fashion during the submission process. SAP uses [the standard DCO text of the Linux Foundation](https://developercertificate.org/).

## License
Copyright (c) 2024 SAP SE or an SAP affiliate company. All rights reserved. This project is licensed under the Apache Software License, version 2.0 except as noted otherwise in the [LICENSE](LICENSE) file.
