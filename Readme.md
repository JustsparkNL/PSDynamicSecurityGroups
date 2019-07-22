![PSDynamicSecurityGroups](src/other/DSG_256.png)

![LicenseBadge](https://img.shields.io/github/license/GraficomGroup/PSDynamicSecurityGroups.svg?style=flat-square)
![PSGalleryVersionBadge](https://img.shields.io/powershellgallery/v/PSDynamicSecurityGroups.svg?style=flat-square)
# PSDynamicSecurityGroups


A PowerShell Module that provides an easy way to create and manage Active Directory Dynamic Security Groups.

## Description

A PowerShell Module that provides an easy way to create and manage Active Directory Dynamic Security Groups.

## Introduction

## Requirements

## Installation

Powershell Gallery (PS 5.0, Preferred method)
`install-module PSDynamicSecurityGroups`

Manual Installation
`iex (New-Object Net.WebClient).DownloadString("https://github.com/GraficomGroup/PSDynamicSecurityGroups/raw/master/Install.ps1")`

Or clone this repository to your local machine, extract, go to the .\releases\PSDynamicSecurityGroups directory
and import the module to your session to test, but not install this module.

## Features

## Versions

1.0.0 - Initial Release

1.0.1 - Updated mandatory flag of description. Updated all functions to the function template.

1.0.2 - Ensure that Update-DSG handles errors gracefully. Removed multiple OU support. Updated License.

## Contribute

Please feel free to contribute by opening new issues or providing pull requests.
For the best development experience, open this project as a folder in Visual
Studio Code and ensure that the PowerShell extension is installed.

* [Visual Studio Code]
* [PowerShell Extension]

## Other Information

**Author:** Justin Perdok, Graficom Group

**Website:** https://github.com/GraficomGroup/PSDynamicSecurityGroups
